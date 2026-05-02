---
layout: post
date: 2025-04-11 08:00:00
updated: 2025-04-11 08:00:00
title: "PowerShell 技能连载 - 远程管理"
description: PowerTip of the Day - PowerShell Remoting
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- remoting
---

_适用于 PowerShell 5.1 及以上版本_

管理一台服务器时，远程桌面（RDP）可能就够了。但当你的环境有十几台甚至上百台服务器时，逐台登录操作就变得不可接受了。PowerShell Remoting 提供了一种高效、可扩展的远程管理方式，让你在一台机器上就能管理整个服务器群。

PowerShell Remoting 基于 WinRM（Windows Remote Management）协议，本质上是对 WS-Management 标准的实现。它不仅支持交互式会话，还支持一对多的批量命令执行，甚至可以跨越信任边界的双跳认证（CredSSP）。本文将从基础配置讲起，逐步深入到高级远程管理场景。

<!-- more -->

## 启用远程管理

在使用 PowerShell Remoting 之前，需要先在目标机器上启用 WinRM 服务。

```powershell
# 在目标机器上启用远程管理（需要管理员权限）
Enable-PSRemoting -Force

# 验证 WinRM 服务状态
Get-Service -Name WinRM | Select-Object Name, Status, StartType
```

```
Name  Status StartType
----  ------ ---------
WinRM Running Automatic
```

如果目标机器在域环境中，通常组策略会自动配置 WinRM。在工作组环境中，可能还需要将客户端添加到目标机器的受信任主机列表。

```powershell
# 将远程主机加入受信任列表（工作组环境）
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "192.168.1.*" -Force

# 查看当前受信任主机配置
Get-Item WSMan:\localhost\Client\TrustedHosts
```

## 交互式会话：Enter-PSSession

`Enter-PSSession` 用于建立一对一的交互式远程会话，就像 SSH 登录到远程主机一样。适合需要逐步排查问题的场景。

```powershell
# 建立交互式远程会话
Enter-PSSession -ComputerName "SRV-PROD-01" -Credential "vichamp\admin"
```

```
[SRV-PROD-01]: PS C:\Users\admin\Documents>
```

进入远程会话后，命令提示符会显示远程机器名。此时输入的每条命令都在远程机器上执行。操作完成后，使用 `Exit-PSSession` 退出。

```powershell
# 在远程会话中执行命令
[SRV-PROD-01]: PS> Get-Service -Name "W3SVC" | Select-Object Name, Status
```

```
Name  Status
----  ------
W3SVC Running
```

```powershell
# 退出远程会话
[SRV-PROD-01]: PS> Exit-PSSession
PS C:\Users\admin\Documents>
```

## 批量远程执行：Invoke-Command

`Invoke-Command` 是远程管理的核心工具，它支持一对多的批量命令执行，是大规模运维自动化的基础。

### 基础用法

```powershell
# 在单台远程机器上执行命令
$result = Invoke-Command -ComputerName "SRV-PROD-01" -ScriptBlock {
    Get-CimInstance -ClassName Win32_OperatingSystem |
        Select-Object CSName, Caption, Version,
            @{N='内存(GB)';E={[math]::Round($_.TotalVisibleMemorySize/1MB, 1)}}
}

$result | Format-Table -AutoSize
```

```
CSName      Caption                       Version 内存(GB)
------      -------                       ------- --------
SRV-PROD-01 Microsoft Windows Server 2022 10.0.20348     32.0
```

### 多台服务器批量执行

```powershell
# 同时在多台服务器上检查磁盘空间
$servers = @("SRV-WEB-01", "SRV-WEB-02", "SRV-DB-01", "SRV-APP-01")

$diskReport = Invoke-Command -ComputerName $servers -ScriptBlock {
    Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" |
        ForEach-Object {
            $usedPercent = [math]::Round(($_.Size - $_.FreeSpace) / $_.Size * 100, 1)
            [PSCustomObject]@{
                服务器    = $env:COMPUTERNAME
                盘符      = $_.DeviceID
                总空间_GB = [math]::Round($_.Size / 1GB, 1)
                剩余_GB   = [math]::Round($_.FreeSpace / 1GB, 1)
                使用率    = "$usedPercent%"
                状态      = if ($usedPercent -gt 90) { "警告" } elseif ($usedPercent -gt 80) { "注意" } else { "正常" }
            }
        }
}

$diskReport | Sort-Object 服务器, 盘符 | Format-Table -AutoSize
```

```
服务器     盘符 总空间_GB 剩余_GB 使用率 状态
------     ---- -------- ------- ------ ----
SRV-APP-01 C:       100.0    45.2  54.8% 正常
SRV-APP-01 D:       500.0    89.5  82.1% 注意
SRV-DB-01  C:       100.0    32.1  67.9% 正常
SRV-DB-01  E:      2000.0   150.2  92.5% 警告
SRV-WEB-01 C:       100.0    68.7  31.3% 正常
SRV-WEB-02 C:       100.0    71.3  28.7% 正常
```

### 传递参数

在远程脚本块中使用 `$using:` 来引用本地变量。

```powershell
# 传递本地变量到远程会话
$logPath = "C:\inetpub\logs"
$daysOld = 7

Invoke-Command -ComputerName $servers -ScriptBlock {
    $cutoff = (Get-Date).AddDays(-$using:daysOld)
    $files = Get-ChildItem -Path $using:logPath -Recurse -File |
        Where-Object { $_.LastWriteTime -lt $cutoff }

    [PSCustomObject]@{
        服务器    = $env:COMPUTERNAME
        旧文件数  = $files.Count
        可释放_MB = [math]::Round(($files | Measure-Object Length -Sum).Sum / 1MB, 1)
    }
} | Format-Table -AutoSize
```

```
服务器     旧文件数 可释放_MB
------     -------- ---------
SRV-WEB-01      125    2450.3
SRV-WEB-02       98    1890.7
SRV-APP-01       45     670.2
SRV-DB-01        12     150.8
```

## 会话复用

每次 `Invoke-Command` 都会建立新的连接，开销较大。通过预先创建 PSSession，可以复用连接，显著提升批量操作的效率。

```powershell
# 创建持久会话
$sessions = New-PSSession -ComputerName $servers

# 在同一组会话中执行多个命令（无需重复建立连接）
# 第一轮：获取服务状态
$svcStatus = Invoke-Command -Session $sessions -ScriptBlock {
    Get-Service -Name "W3SVC","MSSQLSERVER" -ErrorAction SilentlyContinue |
        Select-Object Name, Status
}

# 第二轮：检查 CPU 使用率
$cpuUsage = Invoke-Command -Session $sessions -ScriptBlock {
    $cpu = Get-CimInstance -ClassName Win32_Processor |
        Measure-Object -Property LoadPercentage -Average
    [PSCustomObject]@{
        服务器 = $env:COMPUTERNAME
        CPU使用率 = "$($cpu.Average)%"
    }
}

# 清理会话
Remove-PSSession -Session $sessions
```

## CredSSP 与双跳认证

在远程会话中访问第三台机器（如网络共享、数据库）时，会遇到"第二跳"问题。默认情况下，远程会话中的凭据不能继续传递。CredSSP 可以解决这个问题。

```powershell
# 在客户端启用 CredSSP（以管理员运行）
Enable-WSManCredSSP -Role Client -DelegateComputer "*.vichamp.com" -Force

# 在远程服务器启用 CredSSP
Invoke-Command -ComputerName "SRV-PROD-01" -ScriptBlock {
    Enable-WSManCredSSP -Role Server -Force
}

# 使用 CredSSP 认证建立会话
$cred = Get-Credential "vichamp\admin"
Invoke-Command -ComputerName "SRV-PROD-01" -Authentication CredSSP -Credential $cred -ScriptBlock {
    # 现在可以访问网络共享等需要认证的资源
    Get-ChildItem -Path "\\FILE-SVR\Shared\Reports"
}
```

## JEA 简介

Just Enough Administration（JEA）是 PowerShell Remoting 的安全扩展，它允许你精细控制用户可以在远程会话中执行哪些命令，即使该用户本身没有管理员权限。

```powershell
# JEA 的核心概念（概览）

# 1. 创建角色能力文件（Role Capability）
# 定义用户可以执行哪些命令
$roleCapParams = @{
    Path                   = ".\RoleCapabilities\Maintenance.psrc"
    VisibleCmdlets         = @("Get-Service", "Restart-Service", "Get-Process")
    VisibleFunctions       = @("Get-SystemHealth")
    VisibleExternalCommands = @("C:\Tools\check.exe")
}
New-PSRoleCapabilityFile @roleCapParams

# 2. 创建会话配置文件（Session Configuration）
# 定义谁可以连接，使用哪个角色
$sessionConfigParams = @{
    Path                 = ".\SessionConfigurations\Maintenance.pssc"
    RunAsAccount         = "vichamp\JEA_Service"
    RoleDefinitions      = @{
        "vichamp\MaintenanceTeam" = @{ RoleCapabilities = "Maintenance" }
    }
    TranscriptDirectory  = "C:\JEA\Transcripts"
}
New-PSSessionConfigurationFile @sessionConfigParams

# 3. 注册会话配置
Register-PSSessionConfiguration -Name "Maintenance" -Path ".\SessionConfigurations\Maintenance.pssc"

# 4. 用户连接到 JEA 端点
Enter-PSSession -ComputerName "SRV-PROD-01" -ConfigurationName "Maintenance"
```

JEA 的优势在于：
- 非管理员用户可以执行特定的管理操作
- 所有操作自动记录审计日志（Transcript）
- 使用虚拟账户运行，无需共享管理员密码
- 白名单机制确保用户只能执行允许的命令

## 注意事项

- 生产环境中建议使用 HTTPS 传输，可通过 `Set-Item WSMan:\localhost\Service\EnableCompatibilityHttpsListener -Value $true` 或配置证书实现
- `Invoke-Command` 默认并发限制为 32 个远程连接，可通过 `-ThrottleLimit` 参数调整
- 使用 `Remove-PSSession` 及时清理不再使用的会话，避免资源泄漏
- CredSSP 凭据委托存在安全风险（凭据在远程服务器上可被提取），仅在受信任环境中使用
- JEA 配置需要管理员权限，且建议在域环境中部署以获得最佳效果
- 远程执行时，对象的 `PSComputerName` 属性会自动附加，可用于标识结果来源
