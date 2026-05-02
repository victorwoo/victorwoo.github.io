---
layout: post
date: 2025-08-05 08:00:00
updated: 2025-08-05 08:00:00
title: "PowerShell 技能连载 - SSH 隧道与端口转发"
description: PowerTip of the Day - SSH Tunneling and Port Forwarding in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- ssh
- tunneling
- port-forwarding
- network
- security
---

_适用于 PowerShell 5.1 及以上版本_

在混合环境的运维工作中，并非所有服务都暴露在公网上。数据库、内部 API、管理后台通常隐藏在跳板机或防火墙后面，直接访问需要 VPN 或复杂的网络配置。SSH 隧道（SSH Tunneling）提供了一种轻量、安全的方案，通过加密通道将远程服务映射到本地端口，无需额外的网络基础设施。

Windows 自 OpenSSH 客户端内置以来（Windows 10 1809+、Windows Server 2019+），PowerShell 脚本可以直接调用 `ssh` 命令建立隧道。结合 PowerShell 的进程管理能力，可以动态创建、监控和清理 SSH 隧道，实现自动化的端口转发管理。

本文将讲解 PowerShell 中 SSH 隧道的创建、管理和自动化实践。

<!-- more -->

## 基础本地端口转发

```powershell
# 本地端口转发：将远程数据库映射到本地端口
# 场景：远程 MySQL 在 10.0.1.50:3306，通过跳板机 bastion.example.com 访问

function New-SSHTunnel {
    param(
        [Parameter(Mandatory)]
        [string]$JumpHost,

        [Parameter(Mandatory)]
        [int]$LocalPort,

        [Parameter(Mandatory)]
        [string]$RemoteHost,

        [Parameter(Mandatory)]
        [int]$RemotePort,

        [string]$SshUser = $env:USERNAME,

        [string]$KeyPath
    )

    $sshArgs = @(
        "-N"              # 不执行远程命令
        "-L"              # 本地端口转发
        "${LocalPort}:${RemoteHost}:${RemotePort}"
    )

    if ($KeyPath) {
        $sshArgs += "-i", $KeyPath
    }

    $sshArgs += "${SshUser}@${JumpHost}"

    # 启动 SSH 进程（后台运行）
    $process = Start-Process -FilePath "ssh" `
        -ArgumentList $sshArgs `
        -WindowStyle Hidden `
        -PassThru

    # 等待端口就绪
    $ready = $false
    for ($i = 0; $i -lt 10; $i++) {
        Start-Sleep -Milliseconds 500
        try {
            $tcp = New-Object System.Net.Sockets.TcpClient("127.0.0.1", $LocalPort)
            $tcp.Close()
            $ready = $true
            break
        } catch {
            # 端口尚未就绪，继续等待
        }
    }

    if ($ready) {
        Write-Host "SSH 隧道已建立：localhost:${LocalPort} -> ${RemoteHost}:${RemotePort}" `
            -ForegroundColor Green
        Write-Host "进程 ID：$($process.Id)"
    } else {
        Write-Warning "隧道建立超时，请检查连接参数"
    }

    return $process
}

# 示例：通过跳板机连接远程 MySQL
$tunnel = New-SSHTunnel -JumpHost "bastion.example.com" `
    -LocalPort 13306 `
    -RemoteHost "10.0.1.50" `
    -RemotePort 3306 `
    -SshUser "admin" `
    -KeyPath "$env:USERPROFILE\.ssh\id_rsa"
```

执行结果示例：

```
SSH 隧道已建立：localhost:13306 -> 10.0.1.50:3306
进程 ID：24516
```

## 远程端口转发与动态转发

```powershell
# 远程端口转发：将本地服务暴露给远程网络
# 场景：让远程服务器访问本地开发中的 Web API

function New-SSHRemoteTunnel {
    param(
        [Parameter(Mandatory)]
        [string]$RemoteServer,

        [Parameter(Mandatory)]
        [int]$RemotePort,

        [Parameter(Mandatory)]
        [string]$LocalHost,

        [Parameter(Mandatory)]
        [int]$LocalPort,

        [string]$SshUser = $env:USERNAME
    )

    $sshArgs = @(
        "-N"
        "-R"
        "${RemotePort}:${LocalHost}:${LocalPort}"
        "${SshUser}@${RemoteServer}"
    )

    $process = Start-Process -FilePath "ssh" `
        -ArgumentList $sshArgs `
        -WindowStyle Hidden `
        -PassThru

    Write-Host "远程隧道已建立：${RemoteServer}:${RemotePort} -> ${LocalHost}:${LocalPort}" `
        -ForegroundColor Green
    return $process
}

# 动态端口转发（SOCKS 代理）
function New-SSHSocksProxy {
    param(
        [Parameter(Mandatory)]
        [string]$Server,

        [int]$LocalPort = 1080,

        [string]$SshUser = $env:USERNAME,

        [string]$KeyPath
    )

    $sshArgs = @(
        "-N"
        "-D"               # 动态转发，创建 SOCKS5 代理
        "$LocalPort"
    )

    if ($KeyPath) {
        $sshArgs += "-i", $KeyPath
    }

    $sshArgs += "${SshUser}@${Server}"

    $process = Start-Process -FilePath "ssh" `
        -ArgumentList $sshArgs `
        -WindowStyle Hidden `
        -PassThru

    Write-Host "SOCKS5 代理已启动：127.0.0.1:${LocalPort}" -ForegroundColor Green
    Write-Host "使用方式：配置浏览器或工具使用 SOCKS5 代理 127.0.0.1:${LocalPort}"
    return $process
}

# 示例：创建 SOCKS5 代理
$socks = New-SSHSocksProxy -Server "bastion.example.com" `
    -LocalPort 1080 `
    -SshUser "admin"
```

执行结果示例：

```
SOCKS5 代理已启动：127.0.0.1:1080
使用方式：配置浏览器或工具使用 SOCKS5 代理 127.0.0.1:1080
```

## 隧道生命周期管理

```powershell
# 隧道管理器：统一管理多个 SSH 隧道
$script:TunnelRegistry = @{}

function Register-Tunnel {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][System.Diagnostics.Process]$Process,
        [int]$LocalPort,
        [string]$Target
    )

    $script:TunnelRegistry[$Name] = @{
        Process   = $Process
        LocalPort = $LocalPort
        Target    = $Target
        CreatedAt = Get-Date
        Status    = "Running"
    }
}

function Get-SSHTunnel {
    param([string]$Name)

    if ($Name) {
        $entry = $script:TunnelRegistry[$Name]
        if ($entry) {
            # 检查进程是否仍在运行
            $alive = Get-Process -Id $entry.Process.Id -ErrorAction SilentlyContinue
            $status = if ($alive) { "Running" } else { "Stopped" }
            $entry.Status = $status

            [PSCustomObject]@{
                Name      = $Name
                PID       = $entry.Process.Id
                LocalPort = $entry.LocalPort
                Target    = $entry.Target
                Status    = $status
                Uptime    = (Get-Date) - $entry.CreatedAt
            }
        }
    } else {
        foreach ($key in $script:TunnelRegistry.Keys) {
            Get-SSHTunnel -Name $key
        }
    }
}

function Stop-SSHTunnel {
    param([Parameter(Mandatory)][string]$Name)

    $entry = $script:TunnelRegistry[$Name]
    if (-not $entry) {
        Write-Warning "未找到隧道：$Name"
        return
    }

    $process = $entry.Process
    if ($process -and -not $process.HasExited) {
        Stop-Process -Id $process.Id -Force
        Write-Host "隧道 '$Name' 已停止（PID: $($process.Id)）" -ForegroundColor Yellow
    }

    $script:TunnelRegistry.Remove($Name)
}

# 使用示例
$tunnel1 = New-SSHTunnel -JumpHost "bastion.example.com" `
    -LocalPort 13306 -RemoteHost "10.0.1.50" -RemotePort 3306 -SshUser "admin"
Register-Tunnel -Name "mysql-prod" -Process $tunnel1 -LocalPort 13306 -Target "10.0.1.50:3306"

$tunnel2 = New-SSHTunnel -JumpHost "bastion.example.com" `
    -LocalPort 15432 -RemoteHost "10.0.1.60" -RemotePort 5432 -SshUser "admin"
Register-Tunnel -Name "pg-prod" -Process $tunnel2 -LocalPort 15432 -Target "10.0.1.60:5432"

# 查看所有隧道状态
Get-SSHTunnel | Format-Table -AutoSize
```

执行结果示例：

```
Name       PID   LocalPort Target         Status  Uptime
----       ---   --------- ------         ------  ------
mysql-prod 24516     13306 10.0.1.50:3306 Running 00:02:15
pg-prod    24788     15432 10.0.1.60:5432 Running 00:01:03
```

## 隧道健康检查与自动重连

```powershell
# 隧道守护进程：自动检测断线并重连
function Start-TunnelDaemon {
    param(
        [int]$CheckIntervalSeconds = 30
    )

    Write-Host "隧道守护进程已启动，检查间隔：${CheckIntervalSeconds}秒" -ForegroundColor Cyan

    while ($true) {
        $tunnels = Get-SSHTunnel
        foreach ($t in $tunnels) {
            if ($t.Status -ne "Running") {
                Write-Warning "检测到隧道 '$($t.Name)' 已断开，尝试重连..."

                # 尝试检测端口是否仍被占用（残留进程）
                $portInUse = Get-NetTCPConnection -LocalPort $t.LocalPort `
                    -ErrorAction SilentlyContinue

                if ($portInUse) {
                    Write-Host "端口 $($t.LocalPort) 仍被占用，等待释放..." -ForegroundColor Yellow
                    continue
                }

                # 解析目标地址
                $parts = $t.Target -split ":"
                $remoteHost = $parts[0]
                $remotePort = [int]$parts[1]

                # 重新建立隧道
                $newTunnel = New-SSHTunnel -JumpHost "bastion.example.com" `
                    -LocalPort $t.LocalPort `
                    -RemoteHost $remoteHost `
                    -RemotePort $remotePort `
                    -SshUser "admin"

                if ($newTunnel) {
                    Register-Tunnel -Name $t.Name -Process $newTunnel `
                        -LocalPort $t.LocalPort -Target $t.Target
                    Write-Host "隧道 '$($t.Name)' 重连成功" -ForegroundColor Green
                }
            }
        }

        Start-Sleep -Seconds $CheckIntervalSeconds
    }
}

# 端口连通性测试工具
function Test-TunnelConnectivity {
    param(
        [Parameter(Mandatory)]
        [string]$HostName,

        [Parameter(Mandatory)]
        [int]$Port,

        [int]$TimeoutMs = 3000
    )

    $tcp = New-Object System.Net.Sockets.TcpClient
    $asyncResult = $tcp.BeginConnect($HostName, $Port, $null, $null)
    $waited = $asyncResult.AsyncWaitHandle.WaitOne($TimeoutMs, $false)

    $result = if ($waited -and $tcp.Connected) {
        $tcp.EndConnect($asyncResult)
        [PSCustomObject]@{
            Host   = $HostName
            Port   = $Port
            Status = "Open"
            Latency = "N/A"
        }
    } else {
        [PSCustomObject]@{
            Host   = $HostName
            Port   = $Port
            Status = "Closed"
            Latency = "N/A"
        }
    }

    $tcp.Close()
    return $result
}

# 批量检查所有隧道
Get-SSHTunnel | ForEach-Object {
    Test-TunnelConnectivity -HostName "127.0.0.1" -Port $_.LocalPort
} | Format-Table -AutoSize
```

执行结果示例：

```
隧道守护进程已启动，检查间隔：30秒

Host       Port  Status
----       ----  ------
127.0.0.1 13336  Open
127.0.0.1 15432  Open
```

## 配置文件驱动的隧道管理

```powershell
# 从配置文件批量创建隧道
$tunnelConfigJson = @"
{
    "jumpHost": "bastion.example.com",
    "sshUser": "admin",
    "tunnels": [
        {
            "name": "mysql-prod",
            "localPort": 13306,
            "remoteHost": "10.0.1.50",
            "remotePort": 3306
        },
        {
            "name": "redis-prod",
            "localPort": 16379,
            "remoteHost": "10.0.1.70",
            "remotePort": 6379
        },
        {
            "name": "pg-staging",
            "localPort": 25432,
            "remoteHost": "10.0.2.60",
            "remotePort": 5432
        }
    ]
}
"@

function Start-TunnelsFromConfig {
    param(
        [Parameter(Mandatory)]
        [string]$ConfigPath,

        [string]$KeyPath
    )

    $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json

    $results = @()
    foreach ($t in $config.tunnels) {
        Write-Host "正在建立隧道：$($t.name)..." -ForegroundColor Cyan

        $tunnel = New-SSHTunnel -JumpHost $config.jumpHost `
            -LocalPort $t.localPort `
            -RemoteHost $t.remoteHost `
            -RemotePort $t.remotePort `
            -SshUser $config.sshUser `
            -KeyPath $KeyPath

        Register-Tunnel -Name $t.name -Process $tunnel `
            -LocalPort $t.localPort `
            -Target "$($t.remoteHost):$($t.remotePort)"

        $results += [PSCustomObject]@{
            Name      = $t.name
            LocalPort = $t.localPort
            Target    = "$($t.remoteHost):$($t.remotePort)"
            PID       = $tunnel.Id
        }
    }

    return $results
}

# 保存配置并启动
$tunnelConfigJson | Set-Content "$env:TEMP\tunnels.json" -Encoding UTF8
Start-TunnelsFromConfig -ConfigPath "$env:TEMP\tunnels.json" | Format-Table -AutoSize
```

执行结果示例：

```
正在建立隧道：mysql-prod...
SSH 隧道已建立：localhost:13306 -> 10.0.1.50:3306
正在建立隧道：redis-prod...
SSH 隧道已建立：localhost:16379 -> 10.0.1.70:6379
正在建立隧道：pg-staging...
SSH 隧道已建立：localhost:25432 -> 10.0.2.60:5432

Name        LocalPort Target          PID
----        --------- ------          ---
mysql-prod      13306 10.0.1.50:3306  24516
redis-prod      16379 10.0.1.70:6379  24788
pg-staging      25432 10.0.2.60:5432  25012
```

## 注意事项

1. **端口冲突检查**：创建隧道前务必检查本地端口是否已被占用，避免端口冲突导致隧道建立失败
2. **SSH 密钥管理**：优先使用密钥认证而非密码，密钥文件权限应设置为仅当前用户可读（Windows 上移除继承权限）
3. **连接超时配置**：SSH 默认不发送 keepalive 包，建议在 `~/.ssh/config` 中配置 `ServerAliveInterval 60` 防止空闲断开
4. **进程清理**：脚本异常退出时 SSH 进程可能残留为孤儿进程，应使用 `try/finally` 或注册退出事件确保清理
5. **安全审计**：SSH 隧道可绕过防火墙策略，生产环境中应记录所有隧道的创建和销毁操作，纳入审计日志
6. **网络跳跃限制**：复杂场景需要多级跳板时，使用 SSH ProxyJump（`-J` 参数）比嵌套隧道更可靠且更易维护
