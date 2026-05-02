---
layout: post
date: 2025-09-29 08:00:00
updated: 2025-09-29 08:00:00
title: "PowerShell 技能连载 - SSH 远程管理"
description: PowerTip of the Day - SSH Remoting in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- remoting
- cross-platform
- linux
---

_适用于 PowerShell 7.0 及以上版本（跨平台）_

在传统的 Windows 环境中，PowerShell 远程管理主要依赖 WinRM（Windows Remote Management）协议和 `Enter-PSSession`、`Invoke-Command` 等 cmdlet。然而，WinRM 是 Windows 专属协议，无法在 Linux 或 macOS 上运行，这给跨平台运维带来了不小的障碍。

从 PowerShell 7.0 开始，PowerShell 正式支持基于 SSH 的远程连接。通过 SSH 传输层，你可以使用熟悉的 `Enter-PSSession` 和 `Invoke-Command` 连接到任何安装了 SSH 服务的远程主机，无论对方运行的是 Windows、Linux 还是 macOS。这让 PowerShell 真正成为了一门跨平台的运维语言。

本文将介绍如何配置 SSH 远程管理环境，以及如何使用 PowerShell 通过 SSH 执行远程命令、管理多台服务器。

<!-- more -->

## 环境准备

在使用 SSH 远程管理之前，需要确保本地和远程主机都已正确配置。首先，远程主机上需要安装并运行 SSH 服务（`sshd`），同时需要安装 PowerShell 7。在 Windows 上，可以通过安装 OpenSSH 可选功能来实现；在 Linux 上则通常使用系统自带的 `openssh-server` 包。

以下脚本检查本地 SSH 客户端是否可用，并测试到远程主机的连通性：

```powershell
# 检查 SSH 客户端是否已安装
$sshClient = Get-Command ssh -ErrorAction SilentlyContinue
if ($sshClient) {
    Write-Host "SSH 客户端版本："
    ssh -V 2>&1
} else {
    Write-Host "未找到 SSH 客户端，请先安装 OpenSSH" -ForegroundColor Red
}

# 测试到远程主机的 SSH 连通性
$remoteHost = "192.168.1.100"
$sshTest = Test-Connection -ComputerName $remoteHost -Count 2 -Quiet
if ($sshTest) {
    Write-Host "主机 $remoteHost 网络可达"
} else {
    Write-Host "主机 $remoteHost 无法访问" -ForegroundColor Yellow
}
```

```text
SSH 客户端版本：
OpenSSH_for_Windows_9.5, LibreSSL 3.8.2
主机 192.168.1.100 网络可达
```

## 建立 SSH 远程会话

配置好环境后，就可以使用 `Enter-PSSession` 通过 SSH 连接到远程主机了。与传统的 WinRM 会话不同，SSH 会话需要在 `-HostName` 参数中指定远程主机地址。如果 SSH 使用非默认端口，可以通过 `-Port` 参数指定。

以下代码演示如何建立交互式 SSH 远程会话，以及如何通过 `PSSessionOption` 自定义连接行为：

```powershell
# 定义远程主机信息
$remoteHost = "admin@192.168.1.100"
$sshPort = 22

# 创建会话选项（连接超时 30 秒）
$sessionOption = New-PSSessionOption -OpenTimeout 30000

# 通过 SSH 建立交互式会话
Enter-PSSession -HostName $remoteHost -Port $sshPort -Options $sessionOption

# 进入远程会话后，可以像本地一样执行命令
# PS /home/admin> $PSVersionTable
# PS /home/admin> Get-Process | Select-Object -First 5

# 退出远程会话
Exit-PSSession
```

```text
[admin@192.168.1.100]: PS /home/admin> $PSVersionTable

Name                           Value
----                           -----
PSVersion                      7.4.6
PSEdition                      Core
GitCommitId                    7.4.6
OS                             Ubuntu 24.04.1 LTS
Platform                       Unix
PSCompatibleVersions           {1.0, 2.0, 3.0, 4.0…}
PSRemotingProtocolVersion      2.3
SerializationVersion           1.1.0.1
WSManStackVersion              3.0
```

## 使用 Invoke-Command 执行远程命令

在实际运维场景中，我们经常需要同时在多台远程主机上执行命令。通过 `Invoke-Command` 配合 SSH 传输，可以向多台 Linux 或 Windows 主机批量推送脚本。`Invoke-Command` 的 `-HostName` 参数接受一个字符串数组，因此可以一次连接多台主机。

以下示例展示如何批量查询多台远程服务器的系统信息：

```powershell
# 定义多台远程主机
$servers = @(
    "admin@web-server-01",
    "admin@web-server-02",
    "admin@db-server-01"
)

# 批量查询远程主机的系统信息
$results = Invoke-Command -HostName $servers -ScriptBlock {
    $osInfo = Get-Content /etc/os-release |
        Where-Object { $_ -match '^PRETTY_NAME=' } |
        ForEach-Object { ($_ -split '=')[1].Trim('"') }

    $cpuUsage = (Get-Process | Measure-Object -Property CPU -Sum).Sum
    $memInfo = Get-Content /proc/meminfo |
        Where-Object { $_ -match '^MemAvailable:' }

    [PSCustomObject]@{
        HostName   = $env:COMPUTERNAME ?? hostname
        OS         = $osInfo
        CPU_Total  = [math]::Round($cpuUsage, 2)
        Mem_Info   = $memInfo
        Timestamp  = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    }
}

# 展示结果
$results | Format-Table -AutoSize
```

```text
HostName        OS                         CPU_Total Mem_Info                   Timestamp
--------        --                         --------- --------                   ---------
web-server-01   Ubuntu 24.04.1 LTS              3.42 MemAvailable:    3842 kB  2025-09-29 10:15:32
web-server-02   Ubuntu 24.04.1 LTS              1.87 MemAvailable:    6128 kB  2025-09-29 10:15:33
db-server-01    CentOS Stream 9                  8.15 MemAvailable:   12244 kB  2025-09-29 10:15:33
```

## 使用 SSH 密钥认证

在生产环境中，每次连接都输入密码既不安全也不方便。配置 SSH 密钥认证可以让 PowerShell 远程会话更加流畅。下面展示如何在 PowerShell 中生成 SSH 密钥并将公钥分发到远程主机：

```powershell
# 检查是否已有 SSH 密钥
$sshDir = Join-Path $env:USERPROFILE ".ssh"
$keyPath = Join-Path $sshDir "id_ed25519"

if (-not (Test-Path $keyPath)) {
    # 生成新的 Ed25519 密钥（更安全、更快速）
    Write-Host "正在生成 SSH 密钥..." -ForegroundColor Cyan
    ssh-keygen -t ed25519 -f $keyPath -C "powershell-remoting" -N '""'
    Write-Host "密钥已生成：$keyPath" -ForegroundColor Green
} else {
    Write-Host "已有 SSH 密钥：$keyPath"
}

# 读取公钥内容
$publicKey = Get-Content "$keyPath.pub" -Raw
Write-Host "公钥内容（前 80 字符）："
Write-Host $publicKey.Substring(0, [Math]::Min(80, $publicKey.Length))
```

```text
正在生成 SSH 密钥...
Generating public/private ed25519 key pair.
Your identification has been saved in C:\Users\admin\.ssh\id_ed25519
Your public key has been saved in C:\Users\admin\.ssh\id_ed25519.pub
密钥已生成：C:\Users\admin\.ssh\id_ed25519
公钥内容（前 80 字符）：
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINxR9fG3hK7YpBzM2vWqLpC4T5JkR powershell-remoting
```

## 配置 SSH Config 文件简化连接

当需要管理大量服务器时，可以在 `~/.ssh/config` 文件中预定义主机别名和连接参数。PowerShell 远程管理可以直接使用这些别名，而不必每次都输入完整的用户名和地址。

以下脚本用于生成和维护 SSH Config 文件：

```powershell
# 定义服务器清单
$serverList = @(
    [PSCustomObject]@{ Alias = "web01"; Host = "192.168.1.101"; User = "admin"; Port = 22 }
    [PSCustomObject]@{ Alias = "web02"; Host = "192.168.1.102"; User = "admin"; Port = 22 }
    [PSCustomObject]@{ Alias = "db01";  Host = "192.168.1.201"; User = "dba";   Port = 2222 }
    [PSCustomObject]@{ Alias = "proxy"; Host = "10.0.0.50";     User = "ops";   Port = 22 }
)

# 生成 SSH Config 内容
$configLines = @()
$configLines += "# PowerShell SSH Remoting - Auto Generated"
$configLines += ""

foreach ($server in $serverList) {
    $configLines += "Host $($server.Alias)"
    $configLines += "    HostName $($server.Host)"
    $configLines += "    User $($server.User)"
    $configLines += "    Port $($server.Port)"
    $configLines += "    IdentityFile ~/.ssh/id_ed25519"
    $configLines += "    StrictHostKeyChecking accept-new"
    $configLines += ""
}

# 写入 SSH Config 文件
$sshConfigPath = Join-Path $env:USERPROFILE ".ssh" "config"
$configLines | Set-Content -Path $sshConfigPath -Encoding UTF8
Write-Host "SSH Config 已写入：$sshConfigPath" -ForegroundColor Green

# 验证配置
Write-Host "`n配置内容预览："
Get-Content $sshConfigPath
```

```text
SSH Config 已写入：C:\Users\admin\.ssh\config

配置内容预览：
# PowerShell SSH Remoting - Auto Generated

Host web01
    HostName 192.168.1.101
    User admin
    Port 22
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking accept-new

Host web02
    HostName 192.168.1.102
    User admin
    Port 22
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking accept-new

Host db01
    HostName 192.168.1.201
    User dba
    Port 2222
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking accept-new

Host proxy
    HostName 10.0.0.50
    User ops
    Port 22
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking accept-new
```

配置完成后，可以直接使用别名建立远程会话：

```powershell
# 使用 SSH Config 中定义的别名连接
Enter-PSSession -HostName web01

# 也可以批量执行命令
$webServers = @("web01", "web02")
$diskReport = Invoke-Command -HostName $webServers -ScriptBlock {
    $df = df -h / | Select-Object -Last 1
    $uptime = uptime -p
    [PSCustomObject]@{
        Server    = hostname
        Disk      = $df
        Uptime    = $uptime
        Collected = Get-Date -Format 'HH:mm:ss'
    }
}

$diskReport | Format-List
```

```text
Server    : web-server-01
Disk      : /dev/sda1        50G   23G   25G  48% /
Uptime    : up 42 days, 3 hours, 17 minutes
Collected : 10:22:45

Server    : web-server-02
Disk      : /dev/sda1        50G   18G   29G  39% /
Uptime    : up 42 days, 3 hours, 22 minutes
Collected : 10:22:46
```

## 监控远程主机状态

结合 SSH 远程管理，可以编写一个实用的监控脚本，定期检查远程服务器的健康状态。以下示例通过 SSH 同时检查多台服务器的 CPU、内存和磁盘使用情况：

```powershell
# 监控目标列表
$targets = @("web01", "web02", "db01")

$healthReport = Invoke-Command -HostName $targets -ScriptBlock {
    # CPU 使用率（取 top 的第 3 行）
    $cpuLine = top -bn1 | Select-Object -Index 2
    $cpuIdle = if ($cpuLine -match '(\d+\.\d+)\s*id') {
        [math]::Round(100 - [double]$Matches[1], 1)
    } else {
        -1
    }

    # 内存使用率
    $memLine = free -m | Select-Object -Index 1
    $memParts = $memLine -split '\s+'
    $memTotal = [int]$memParts[1]
    $memUsed  = [int]$memParts[2]
    $memPct   = [math]::Round(($memUsed / $memTotal) * 100, 1)

    # 磁盘使用率
    $diskLine = df -h / | Select-Object -Last 1
    $diskPct  = if ($diskLine -match '(\d+)%') { [int]$Matches[1] } else { -1 }

    # 判断健康状态
    $status = "Healthy"
    if ($cpuIdle -gt 80 -or $memPct -gt 85 -or $diskPct -gt 80) {
        $status = "Warning"
    }
    if ($cpuIdle -gt 95 -or $memPct -gt 95 -or $diskPct -gt 90) {
        $status = "Critical"
    }

    [PSCustomObject]@{
        Server   = hostname
        CPU_Pct  = $cpuIdle
        Mem_Pct  = $memPct
        Disk_Pct = $diskPct
        Status   = $status
    }
}

# 输出报告，按状态排序
$healthReport |
    Sort-Object { switch ($_.Status) { "Critical" { 0 } "Warning" { 1 } default { 2 } } } |
    Format-Table -AutoSize

# 统计
$critical = ($healthReport | Where-Object { $_.Status -eq "Critical" }).Count
$warning  = ($healthReport | Where-Object { $_.Status -eq "Warning" }).Count
$healthy  = ($healthReport | Where-Object { $_.Status -eq "Healthy" }).Count

Write-Host "`n汇总：健康 $healthy 台 / 警告 $warning 台 / 严重 $critical 台"
```

```text
Server        CPU_Pct Mem_Pct Disk_Pct Status
------        ------- ------- -------- ------
db-server-01     12.3    88.2       72 Warning
web-server-01     5.1    42.6       48 Healthy
web-server-02     3.8    38.1       39 Healthy

汇总：健康 2 台 / 警告 1 台 / 严重 0 台
```

## 注意事项

1. **SSH 服务必须运行**：远程主机上的 `sshd` 服务必须处于运行状态。在 Linux 上可通过 `systemctl status sshd` 检查，在 Windows 上可通过 `Get-Service sshd` 查看。

2. **PowerShell 版本要求**：远程主机上必须安装 PowerShell 7 及以上版本。仅安装 SSH 不够，`sshd` 还需要配置 `powershell` 作为可用子系统（在 `sshd_config` 中添加 `Subsystem powershell /usr/bin/pwsh -sshs -NoLogo`）。

3. **密钥权限**：在 Linux/macOS 上，SSH 私钥文件的权限必须设为 `600`，否则 SSH 会拒绝使用该密钥。可通过 `chmod 600 ~/.ssh/id_ed25519` 修复。

4. **防火墙与端口**：确保本地到远程主机的 SSH 端口（默认 22）在防火墙规则中放行。如果使用非默认端口，需要在 `SSH Config` 中显式指定或通过 `-Port` 参数传入。

5. **错误排查**：如果连接失败，先用 `ssh user@host` 命令行工具手动测试，排除认证和网络问题。PowerShell SSH 远程管理底层依赖系统的 SSH 客户端，所以基础连通性必须先保证。

6. **与 WinRM 的区别**：SSH 远程会话不支持 CimCmdlets 和部分 WMI 相关操作（这些是 Windows 专属）。如果需要管理 Windows 专属功能（如注册表、服务控制管理器），建议对 Windows 目标仍然使用 WinRM 传输，对 Linux/macOS 目标使用 SSH 传输。
