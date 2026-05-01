---
layout: post
date: 2025-12-19 08:00:00
title: "PowerShell 技能连载 - SSH 远程管理"
description: "PowerTip of the Day - SSH Remoting in PowerShell"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- ssh
- remoting
- linux
- cross-platform
---

_适用于 PowerShell 7.0 及以上版本_

传统的 PowerShell Remoting 基于 WinRM（Windows Remote Management）协议，虽然功能强大，但存在明显的平台限制——它只能在 Windows 环境中工作。在企业混合环境中，运维人员往往需要同时管理 Windows 和 Linux 服务器，WinRM 的局限性就成了一个棘手的问题。此外，WinRM 在防火墙策略严格的网络中配置繁琐，端口和认证方式也不够灵活。

PowerShell 7 引入了基于 SSH 的远程会话支持，彻底改变了这一局面。通过 `Enter-PSSession` 和 `Invoke-Command` 的 `-HostName` 参数，PowerShell 可以通过 SSH 协议建立远程连接，实现真正的跨平台远程管理。这意味着你可以从 Windows 管理 Linux 服务器、从 Linux 管理 Windows 服务器，甚至可以在云环境和容器中使用统一的远程管理体验。

SSH Remoting 不仅能与现有的 SSH 基础设施无缝集成，还支持密钥认证、跳板机（ProxyJump）、多主机并行执行等高级场景。本文将介绍如何配置和使用 PowerShell SSH Remoting，以及在混合环境中的实战技巧。

## SSH 远程会话配置与基础操作

在使用 SSH Remoting 之前，需要确保目标主机已安装并运行 SSH 服务。PowerShell 7 在连接时会使用系统自带的 SSH 客户端，因此无需额外安装 WinRM。

以下示例展示如何通过 SSH 建立交互式远程会话和执行远程命令：

```powershell
# 查看当前 PowerShell 版本，确认是否支持 SSH Remoting
$PSVersionTable.PSVersion

# 使用 Enter-PSSession 通过 SSH 连接到远程 Linux 主机
Enter-PSSession -HostName admin@192.168.1.100
# 在远程会话中执行命令
hostname
uname -a
whoami
# 退出远程会话
Exit-PSSession

# 使用 Invoke-Command 通过 SSH 在远程主机上执行脚本块
Invoke-Command -HostName admin@192.168.1.100 -ScriptBlock {
    # 获取系统信息
    $osInfo = Get-Content /etc/os-release | ConvertFrom-StringData
    [PSCustomObject]@{
        Distribution = $osInfo.NAME
        Version      = $osInfo.VERSION
        Kernel       = uname -r
        Uptime       = (uptime -p)
        MemoryTotal  = "#{math.Round((Get-Content /proc/meminfo |
            Select-String 'MemTotal').ToString().Split()[1] / 1MB, 2)} GB"
    }
}

# 指定 SSH 端口（非默认 22 端口的情况）
$session = New-PSSession -HostName admin@192.168.1.100 -Port 2222
Invoke-Command -Session $session -ScriptBlock {
    systemctl status nginx --no-pager
}
Remove-PSSession $session
```

执行结果示例：

```
Major  Minor  Patch  PreReleaseLabel BuildLabel
-----  -----  -----  --------------- ----------
7      4      0

[admin@192.168.1.100]: PS /home/admin> hostname
web-server-01
[admin@192.168.1.100]: PS /home/admin> uname -a
Linux web-server-01 5.15.0-91-generic #101-Ubuntu SMP x86_64 GNU/Linux
[admin@192.168.1.100]: PS /home/admin> whoami
admin

Distribution      : Ubuntu 22.04.3 LTS
Version           : 22.04.3 LTS (Jammy Jellyfish)
Kernel            : 5.15.0-91-generic
Uptime            : up 42 days, 3 hours
MemoryTotal       : 15.62 GB

nginx.service - A high performance web server
     Loaded: loaded (/lib/systemd/system/nginx.service; enabled)
     Active: active (running) since Mon 2025-12-01 08:00:00 UTC
```

## SSH 密钥认证与多主机管理

密码认证虽然简单，但在自动化场景中存在安全和管理上的问题。SSH 密钥认证不仅更安全，还能让脚本在无人值守的情况下自动运行。PowerShell 7 的 SSH Remoting 原生支持密钥认证，同时可以通过 SSH 配置文件管理多个目标主机。

```powershell
# 生成 SSH 密钥对（如果尚未生成）
ssh-keygen -t ed25519 -C "powershell-remoting" -f ~/.ssh/id_ed25519

# 将公钥复制到远程主机（使用 ssh-copy-id）
ssh-copy-id -i ~/.ssh/id_ed25519.pub admin@192.168.1.100
ssh-copy-id -i ~/.ssh/id_ed25519.pub admin@192.168.1.101
ssh-copy-id -i ~/.ssh/id_ed25519.pub admin@192.168.1.102

# 配置 SSH config 文件，简化连接管理
$sshConfig = @"
Host web-server
    HostName 192.168.1.100
    User admin
    Port 22
    IdentityFile ~/.ssh/id_ed25519

Host db-server
    HostName 192.168.1.101
    User admin
    Port 22
    IdentityFile ~/.ssh/id_ed25519

Host app-server
    HostName 192.168.1.102
    User admin
    Port 2222
    IdentityFile ~/.ssh/id_ed25519
"@

# 将配置写入 SSH config 文件
$sshConfigPath = "$HOME/.ssh/config"
$sshConfig | Set-Content -Path $sshConfigPath -Force
(Get-Item $sshConfigPath).Attributes = 'ReadOnly'

# 使用 SSH 别名直接连接（无需输入密码）
Enter-PSSession -HostName web-server

# 通过密钥认证在多台主机上并行执行命令
$servers = @('web-server', 'db-server', 'app-server')
$results = Invoke-Command -HostName $servers -ScriptBlock {
    [PSCustomObject]@{
        Host      = $env:COMPUTERNAME ?? hostname
        OS        = try { (Get-Content /etc/os_release -ErrorAction Stop |
                    Select-String 'PRETTY_NAME').ToString().Split('"')[1] }
                  catch { $PSVersionTable.OS }
        PSVersion = $PSVersionTable.PSVersion.ToString()
        CPU_Usage = (Get-Process | Measure-Object CPU -Maximum).Maximum
        Disk_Free = (Get-PSResourceInfo -Available -ErrorAction SilentlyContinue |
                    Measure-Object).Count
    }
} | Select-Object Host, OS, PSVersion

$results | Format-Table -AutoSize
```

执行结果示例：

```
Generating public/private ed25519 key pair.
Your identification has been saved in /home/user/.ssh/id_ed25519
Your public key has been saved in /home/user/.ssh/id_ed25519.pub

Host        OS                      PSVersion
----        --                      ---------
web-server  Ubuntu 22.04.3 LTS      7.4.0
db-server   Ubuntu 22.04.3 LTS      7.4.0
app-server  Debian 12.4             7.3.2
```

## 混合环境自动化：Windows + Linux 批量操作

在企业环境中，Windows 和 Linux 服务器通常共存。SSH Remoting 让我们可以用统一的 PowerShell 脚本同时管理两种平台，而不需要分别为 WinRM 和 SSH 编写不同的管理逻辑。下面的示例展示了如何在混合环境中进行批量巡检和配置管理。

```powershell
# 定义混合主机列表（Windows 用 -ComputerName，Linux 用 -HostName）
$windowsServers = @('WIN-SVR01', 'WIN-SVR02')
$linuxServers   = @('web-server', 'db-server', 'app-server')

# Windows 主机通过 WinRM 获取信息
$winResults = Invoke-Command -ComputerName $windowsServers -ScriptBlock {
    [PSCustomObject]@{
        Host        = $env:COMPUTERNAME
        Platform    = 'Windows'
        OS_Version  = [System.Environment]::OSVersion.VersionString
        CPU_Count   = $env:NUMBER_OF_PROCESSORS
        Memory_GB   = [math]::Round(
            (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2
        )
        Disk_Free_GB = [math]::Round(
            (Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" |
             Measure-Object FreeSpace -Sum).Sum / 1GB, 2
        )
        Uptime_Days = ((Get-Date) - (Get-CimInstance Win32_OperatingSystem).
                       LastBootUpTime).Days
    }
}

# Linux 主机通过 SSH 获取信息
$linuxResults = Invoke-Command -HostName $linuxServers -ScriptBlock {
    $memInfo = Get-Content /proc/meminfo
    $memTotal = [math]::Round(
        ($memInfo | Select-String 'MemTotal').ToString().Split()[1] / 1MB, 2
    )
    $diskFree = [math]::Round(
        (df -BG / | Select-Object -Last 1).ToString().Split()[3] -replace 'G',''
    )
    $uptimeDays = [math]::Floor(
        (Get-Content /proc/uptime).ToString().Split('.')[0] / 86400
    )

    [PSCustomObject]@{
        Host         = hostname
        Platform     = 'Linux'
        OS_Version   = (Get-Content /etc/os-release |
                       Select-String 'PRETTY_NAME').ToString().Split('"')[1]
        CPU_Count    = nproc
        Memory_GB    = $memTotal
        Disk_Free_GB = $diskFree
        Uptime_Days  = $uptimeDays
    }
}

# 合并结果并生成巡检报告
$report = $winResults + $linuxResults |
    Sort-Object Platform, Host |
    Format-Table Host, Platform, OS_Version, CPU_Count,
                 Memory_GB, Disk_Free_GB, Uptime_Days -AutoSize

$report | Out-String | Write-Host

# 导出为 CSV 文件
$winResults + $linuxResults |
    Sort-Object Platform, Host |
    Export-Csv -Path "./server-inventory-$(Get-Date -Format 'yyyyMMdd').csv" `
               -NoTypeInformation -Encoding UTF8

Write-Host "巡检报告已导出到 CSV 文件" -ForegroundColor Green
```

执行结果示例：

```
Host        Platform OS_Version                      CPU_Count Memory_GB Disk_Free_GB Uptime_Days
----        -------- ----------                      --------- --------- ------------ -----------
WIN-SVR01   Windows  Microsoft Windows Server 2022   8         32.00     156.43       45
WIN-SVR02   Windows  Microsoft Windows Server 2022   4         16.00     89.21        30
app-server  Linux    Debian GNU/Linux 12 (bookworm)   2         7.81      34          62
db-server   Linux    Ubuntu 22.04.3 LTS (Jammy)      4         15.62     120         42
web-server  Linux    Ubuntu 22.04.3 LTS (Jammy)      2         3.91      18          42

巡检报告已导出到 CSV 文件
```

## 注意事项

1. **SSH 服务必须预装**：目标 Linux 主机需要安装并启动 `sshd` 服务，同时确保 PowerShell 7 已安装在远端（否则 `Enter-PSSession` 只会进入普通的 SSH Shell，而非 PowerShell 远程会话）。

2. **认证方式选择**：生产环境应优先使用 SSH 密钥认证（Ed25519 或 RSA），避免在脚本中硬编码密码。密钥的私钥文件务必设置严格的文件权限（`chmod 600`）。

3. **SSH 配置文件的作用**：通过 `~/.ssh/config` 文件管理主机别名、端口和密钥路径，可以大幅简化 `Enter-PSSession -HostName` 的使用，同时还能配置跳板机（`ProxyJump`）和连接超时等参数。

4. **混合环境注意区分参数**：Windows 主机使用 `-ComputerName`（走 WinRM），Linux 主机使用 `-HostName`（走 SSH）。如果 Windows 主机也配置了 SSH 服务，也可以统一使用 `-HostName` 参数。

5. **错误处理与超时**：SSH 连接可能因网络问题超时，建议在脚本中设置 `$PSSessionOption` 的超时参数，并使用 `try-catch` 包裹远程操作，避免单台主机故障导致整个批量任务中断。

6. **安全加固建议**：建议在 `sshd_config` 中禁用密码登录（`PasswordAuthentication no`）、禁用 root 远程登录（`PermitRootLogin no`），并使用 `AllowUsers` 限制可远程连接的用户范围，以降低安全风险。
