---
layout: post
date: 2025-05-01 08:00:00
updated: 2025-05-01 08:00:00
title: "PowerShell 技能连载 - SSH 远程管理"
description: PowerTip of the Day - SSH Remote Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- remoting
- linux
---

_适用于 PowerShell 7.0 及以上版本（跨平台）_

传统上，PowerShell 远程管理依赖 Windows 专属的 WinRM 协议和 `Enter-PSSession` 命令。但随着 PowerShell 7 的跨平台演进，以及混合云环境的普及，基于 SSH 的远程管理已成为官方推荐的新标准。SSH 不仅天然支持 Linux/macOS，还能在 Windows 上与 OpenSSH 无缝集成，实现真正的跨平台远程操作。

本文将从安装配置 OpenSSH 开始，逐步讲解如何通过 SSH 建立 PowerShell 远程会话、传输文件、执行远程命令，以及在生产环境中配置密钥认证和跳板机。

<!-- more -->

## 安装与配置 OpenSSH

在 Windows 上使用 SSH 远程管理，首先需要确保 OpenSSH 服务器已安装并运行。Windows 10 1809 及以上版本和 Windows Server 2019 均内置了 OpenSSH，但默认未启用。

```powershell
# 检查 OpenSSH 安装状态
Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH*'

# 安装 OpenSSH 服务器
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# 启动 SSH 服务并设为自动启动
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

# 确认防火墙规则（安装时通常会自动创建）
Get-NetFirewallRule -Name *ssh*
```

执行结果示例：

```
Name  : OpenSSH.Server~~~~0.0.1.0
State : Installed

Status  Name               DisplayName
------  ----               -----------
Running sshd              OpenSSH SSH Server

Name                  : OpenSSH-Server-In-TCP
DisplayName           : OpenSSH SSH Server (sshd)
Enabled               : True
Direction             : Inbound
```

> **注意**：如果需要在 Linux 上使用 SSH 远程管理，确保目标主机已安装 `openssh-server`，并且 `sshd_config` 中配置了 `Subsystem powershell /usr/bin/pwsh -sshs -NoLogo`。

## 配置 SSH 用于 PowerShell 远程

要让 PowerShell 通过 SSH 建立远程会话，需要在 SSH 服务端进行配置。核心是将 PowerShell 注册为 SSH 子系统（Subsystem），这样客户端连接时可以指定使用 PowerShell 而非默认的 shell。

```powershell
# Windows 上的 sshd_config 路径
$sshdConfig = "$env:ProgramData\ssh\sshd_config"

# 检查是否已配置 PowerShell 子系统
$content = Get-Content $sshdConfig -Raw
if ($content -notmatch 'Subsystem\s+powershell') {
    # 追加 PowerShell 子系统配置
    $subsystemPath = (Get-Command pwsh).Source.Replace('\', '/')
    Add-Content -Path $sshdConfig -Value "`nSubsystem powershell $subsystemPath -sshs -NoLogo"
    Write-Host "已添加 PowerShell 子系统配置" -ForegroundColor Green
} else {
    Write-Host "PowerShell 子系统已配置" -ForegroundColor Yellow
}

# 重启 SSH 服务使配置生效
Restart-Service sshd
```

执行结果示例：

```
已添加 PowerShell 子系统配置
```

配置完成后，还需要确保 `sshd_config` 中启用了密码认证或公钥认证：

```powershell
# 确认认证方式配置
Select-String -Path $sshdConfig -Pattern 'PasswordAuthentication|PubkeyAuthentication'
```

执行结果示例：

```
sshd_config:37:PasswordAuthentication yes
sshd_config:53:PubkeyAuthentication yes
```

## 建立远程会话

配置完成后，使用 `New-PSSession` 或 `Enter-PSSession` 通过 SSH 连接远程主机。连接时通过 `-HostName` 参数指定目标，PowerShell 会自动使用 SSH 协议。

```powershell
# 交互式进入远程会话
Enter-PSSession -HostName admin@192.168.1.100

# 指定 SSH 端口
Enter-PSSession -HostName admin@192.168.1.100 -Port 2222

# 使用 PSSession 对象进行非交互操作
$session = New-PSSession -HostName admin@192.168.1.100
Invoke-Command -Session $session -ScriptBlock {
    $PSVersionTable
    Get-ComputerInfo | Select-Object CsName, OsName, OsVersion
}
```

执行结果示例：

```
PSRemote> [admin@SERVER01]: PS C:\Users\admin\Documents>

Name                           Value
----                           -----
PSVersion                      7.4.2
PSEdition                      Core
Platform                       Unix
OS                             Ubuntu 22.04.4 LTS

CsName     OsName           OsVersion
------     ------           ----------
UBUNTU01   Ubuntu 22.04 LTS 22.04.4
```

> **注意**：`-HostName` 参数使用 `user@host` 格式，与 SSH 命令行一致。首次连接时会提示确认主机指纹。

## 使用 SSH 密钥认证

密码认证存在暴力破解风险，生产环境强烈建议使用 SSH 密钥认证。PowerShell 完全支持基于密钥的 SSH 连接。

```powershell
# 生成 ED25519 密钥对（推荐，比 RSA 更安全更快）
ssh-keygen -t ed25519 -C "admin@workstation" -f "$env:USERPROFILE\.ssh\id_ed25519"

# 生成 RSA 密钥对（兼容性更好）
ssh-keygen -t rsa -b 4096 -C "admin@workstation" -f "$env:USERPROFILE\.ssh\id_rsa"

# 查看生成的公钥
Get-Content "$env:USERPROFILE\.ssh\id_ed25519.pub"
```

执行结果示例：

```
Generating public/private ed25519 key pair.
Enter passphrase (empty for no passphrase):
Your identification has been saved in C:\Users\admin\.ssh\id_ed25519
Your public key has been saved in C:\Users\admin\.ssh\id_ed25519.pub
The key fingerprint is:
SHA256:AbCdEfGhIjKlMnOpQrStUvWxYz1234567890abcdef admin@workstation

ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAbCdEfGh admin@workstation
```

将公钥部署到远程主机：

```powershell
# Windows 目标：将公钥添加到 authorized_keys
$publicKey = Get-Content "$env:USERPROFILE\.ssh\id_ed25519.pub"
$remotePath = "$env:ProgramData\ssh\administrators_authorized_keys"

# 通过 SSH 复制公钥（类 ssh-copy-id 功能）
$remoteHost = "admin@192.168.1.100"
ssh $remoteHost "mkdir -p ~/.ssh && echo '$publicKey' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

# 使用密钥连接（不再需要密码）
Enter-PSSession -HostName $remoteHost -KeyFilePath "$env:USERPROFILE\.ssh\id_ed25519"
```

执行结果示例：

```
PSRemote> [admin@SERVER01]: PS C:\Users\admin\Documents>
```

## 跨平台远程管理

SSH 最大的优势在于跨平台。同一台 Windows 管理机可以同时管理 Windows、Linux 甚至 macOS 主机：

```powershell
# 同时连接多台不同操作系统的主机
$windowsHost = New-PSSession -HostName admin@win-server01
$linuxHost = New-PSSession -HostName dev@linux-web01
$macHost = New-PSSession -HostName user@mac-build01

# 在所有主机上执行命令
$sessions = $windowsHost, $linuxHost, $macHost
$results = Invoke-Command -Session $sessions -ScriptBlock {
    [PSCustomObject]@{
        Host      = $env:COMPUTERNAME ?? hostname
        OS        = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription
        PSVersion = $PSVersionTable.PSVersion.ToString()
        Platform  = $PSVersionTable.Platform
        Uptime    = if ($IsLinux -or $IsMacOS) {
            (uptime -p 2>$null) ?? "N/A"
        } else {
            (Get-CimInstance Win32_OperatingSystem).LastBootUpTime.ToString()
        }
    }
}

$results | Format-Table -AutoSize
```

执行结果示例：

```
Host         OS                                    PSVersion Platform  Uptime
----         --                                    --------- --------  ------
WIN-SERVER01 Microsoft Windows 10.0.20348         7.4.2     Win32NT   4/28/2025 8:30:00 AM
linux-web01  Linux 5.15.0-101-generic #111-Ubuntu 7.4.2     Unix      up 42 days, 3:17
mac-build01  Darwin 23.4.0 Darwin Kernel Version… 7.4.2     Unix      up 15 days, 7:22
```

## 批量远程操作

在运维场景中，经常需要对多台服务器批量执行命令。结合 SSH 和 PowerShell 远程，可以轻松实现并行批量操作：

```powershell
# 从 inventory 文件读取服务器列表
$servers = @(
    @{ Name = 'web-01'; Host = 'admin@192.168.1.101'; Key = 'C:\Keys\web-01\id_ed25519' }
    @{ Name = 'web-02'; Host = 'admin@192.168.1.102'; Key = 'C:\Keys\web-02\id_ed25519' }
    @{ Name = 'db-01';  Host = 'admin@192.168.1.201'; Key = 'C:\Keys\db-01\id_ed25519' }
)

# 批量建立 SSH 会话
$sessions = foreach ($srv in $servers) {
    New-PSSession -HostName $srv.Host -KeyFilePath $srv.Key -Name $srv.Name
}

# 并行执行系统检查
Invoke-Command -Session $sessions -ScriptBlock {
    [PSCustomObject]@{
        Host       = $env:COMPUTERNAME ?? hostname
        CPU_Load   = if ($IsLinux) { (top -bn1 | grep 'Cpu(s)' | awk '{print $2}') } else { (Get-CimInstance Win32_Processor).LoadPercentage }
        Mem_Used_Pct = if ($IsLinux) {
            [math]::Round((free | awk '/Mem/{print $3/$2 * 100}'), 1)
        } else {
            $os = Get-CimInstance Win32_OperatingSystem
            [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize * 100, 1)
        }
        Disk_Free_GB = if ($IsLinux) {
            [math]::Round((df -h / | awk 'NR==2{print $4}' | sed 's/G//'), 1)
        } else {
            [math]::Round((Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'").FreeSpace / 1GB, 1)
        }
    }
} | Sort-Object PSComputerName | Format-Table -AutoSize
```

执行结果示例：

```
Host       CPU_Load Mem_Used_Pct Disk_Free_GB
----       -------- ----------- ------------
web-01     12.3     45.2        128.5
web-02     8.7      38.9        95.2
db-01      65.4     82.1        45.8
```

## SSH 配置文件优化

频繁输入完整的主机名、端口和密钥路径很繁琐。通过配置 SSH config 文件可以简化操作：

```powershell
# 生成 SSH config 文件
$sshConfig = @"
Host web-01
    HostName 192.168.1.101
    User admin
    Port 22
    IdentityFile C:\Keys\web-01\id_ed25519
    RequestTTY yes

Host web-02
    HostName 192.168.1.102
    User admin
    Port 22
    IdentityFile C:\Keys\web-02\id_ed25519

Host db-01
    HostName 192.168.1.201
    User admin
    Port 2222
    IdentityFile C:\Keys\db-01\id_ed25519

Host jump-server
    HostName 10.0.0.1
    User gateway
    IdentityFile C:\Keys\gateway\id_ed25519
"@

Set-Content -Path "$env:USERPROFILE\.ssh\config" -Value $sshConfig -Encoding UTF8
Write-Host "SSH 配置文件已更新" -ForegroundColor Green

# 现在可以使用别名连接
Enter-PSSession -HostName web-01
```

执行结果示例：

```
SSH 配置文件已更新
PSRemote> [admin@WEB-01]: PS C:\Users\admin\Documents>
```

> **注意**：SSH config 文件的权限必须正确设置。在 Windows 上，确保只有当前用户有读取权限；在 Linux/macOS 上，权限应为 `600`。

## 通过跳板机连接

在生产环境中，服务器通常位于内网，需要通过跳板机（Bastion Host）访问。SSH 的 ProxyJump 功能可以轻松实现：

```powershell
# 在 SSH config 中配置跳板机
$jumpConfig = @"

Host prod-*
    ProxyJump jump-server
    User admin
    IdentityFile C:\Keys\prod\id_ed25519

Host prod-web-01
    HostName 10.10.1.101

Host prod-db-01
    HostName 10.10.1.201
"@

Add-Content -Path "$env:USERPROFILE\.ssh\config" -Value $jumpConfig

# 连接会自动经过跳板机
Enter-PSSession -HostName prod-web-01
```

执行结果示例：

```
PSRemote> [admin@PROD-WEB-01]: PS C:\Users\admin\Documents>
```

## 注意事项

1. **SSH 服务安全加固**：生产环境应禁用密码认证，仅启用密钥认证，在 `sshd_config` 中设置 `PasswordAuthentication no`
2. **密钥保护**：私钥文件权限必须设为仅所有者可读（Linux/macOS: `chmod 600`，Windows: 移除继承权限，仅保留当前用户）
3. **会话超时**：SSH 连接可能因防火墙或 NAT 超时断开，建议在 `~/.ssh/config` 中配置 `ServerAliveInterval 60`
4. **跨平台差异**：通过 SSH 执行命令时，目标平台的路径分隔符、环境变量和命令语法可能不同，使用 `$IsLinux`、`$IsWindows`、`$IsMacOS` 进行条件判断
5. **端口安全**：避免使用默认的 22 端口暴露在公网，如果必须暴露，配合 fail2ban 或 Azure/JumpServer 等堡垒机方案
6. **PowerShell 子系统路径**：确保 `sshd_config` 中 `Subsystem powershell` 指向正确的 `pwsh` 路径，Linux 上通常为 `/usr/bin/pwsh`
