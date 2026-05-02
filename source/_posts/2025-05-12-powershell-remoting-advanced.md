---
layout: post
date: 2025-05-12 08:00:00
updated: 2025-05-12 08:00:00
title: "PowerShell 技能连载 - 远程管理进阶"
description: PowerTip of the Day - Advanced PowerShell Remoting
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- remoting
- winrm
- remote-management
---

_适用于 PowerShell 5.1 及以上版本（Windows）_

在前面的文章中，我们介绍了 SSH 远程管理的基础用法。本文将深入 PowerShell 远程管理的进阶技巧，包括 WinRM 配置优化、会话管理、 constrained endpoints（受限端点）、远程调试，以及大规模并行远程操作的策略。

## WinRM 配置优化

WinRM 是 PowerShell 远程管理的默认传输协议。了解其配置项对排查连接问题和优化性能至关重要：

```powershell
# 查看 WinRM 服务状态
Get-Service WinRM

# 快速配置 WinRM（启用远程管理）
winrm quickconfig

# 查看 WinRM 完整配置
winrm get winrm/config

# 查看 WinRM 监听器
winrm enumerate winrm/config/listener

# 常用配置优化
# 增加最大内存限制（默认 150MB，处理大量数据时可能不够）
Set-Item WSMan:\localhost\Shell\MaxMemoryPerShellMB 1024

# 增加并发 shell 数
Set-Item WSMan:\localhost\Shell\MaxShellsPerUser 50

# 增加最大接收数据大小
Set-Item WSMan:\localhost\Shell\MaxEnvelopeSizeKB 8192

# 配置可信主机（用于工作组环境）
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "SRV01,SRV02,192.168.1.*" -Force
```

执行结果示例：

```
Status   Name               DisplayName
------   ----               -----------
Running  WinRM              Windows Remote Management (WS-Management)

WinRM service is already running on this machine.
WinRM is already set up for remote management on this computer.

Config
    MaxEnvelopeSizekb = 8192
    MaxTimeoutms = 60000
    MaxBatchItems = 32000
```

> **注意**：在域环境中，WinRM 默认使用 Kerberos 认证，无需额外配置。在工作组环境中，需要配置 `TrustedHosts` 或使用 HTTPS 端点。

## 会话管理最佳实践

`PSSession` 是远程操作的核心对象。正确管理会话可以避免资源泄漏和连接超时：

```powershell
# 创建持久会话（可复用）
$session = New-PSSession -ComputerName SRV01 -Name "AdminSession"

# 查看所有活动会话
Get-PSSession | Format-Table Name, ComputerName, State, Availability -AutoSize

# 在会话中执行多个命令（保持状态）
Invoke-Command -Session $session -ScriptBlock {
    # 第一个命令设置变量
    $script:logPath = "C:\Logs\app.log"
    $script:logContent = Get-Content $script:logPath -Tail 100
    Write-Host "已加载 $($script:logContent.Count) 行日志"
}

Invoke-Command -Session $session -ScriptBlock {
    # 第二个命令使用之前的变量
    $errors = $script:logContent | Select-String "ERROR"
    $errors | Group-Object | Sort-Object Count -Descending |
        Select-Object Count, Name | Format-Table -AutoSize
}

# 使用完成后释放会话
Remove-PSSession -Session $session

# 批量清理所有断开的会话
Get-PSSession | Where-Object State -eq 'Disconnected' | Remove-PSSession
```

执行结果示例：

```
Name          ComputerName State       Availability
----          ------------ -----       ------------
AdminSession  SRV01        Opened      Available

已加载 100 行日志

Count Name
----- ----
   15 ERROR Database connection timeout
    8 ERROR Failed to authenticate user
    3 ERROR Disk space critically low
```

## 断开与重连会话

PowerShell 3.0 及以上版本支持会话断开与重连，这在网络不稳定时特别有用：

```powershell
# 创建会话
$session = New-PSSession -ComputerName SRV01

# 启动长时间任务
Invoke-Command -Session $session -ScriptBlock {
    # 模拟长时间任务
    1..100 | ForEach-Object {
        Start-Sleep -Seconds 1
        "处理进度：$_/100"
    }
} -AsJob

# 断开会话（任务继续在远程运行）
Disconnect-PSSession -Session $session

# 查看断开的会话
Get-PSSession | Where-Object State -eq 'Disconnected'

# 稍后重连
Connect-PSSession -Session $session

# 检查任务状态
Invoke-Command -Session $session -ScriptBlock {
    Get-Job | Receive-Job -Keep
}
```

执行结果示例：

```
Id Name            ComputerName    State         ConfigurationName     Availability
-- ----            ------------    -----         -----------------     ------------
 1 Session1        SRV01           Disconnected  Microsoft.PowerShell  None

处理进度：1/100
处理进度：2/100
...
处理进度：42/100
```

## 受限端点（Constrained Endpoint）

在企业环境中，可能需要给非管理员提供受限的远程管理能力。通过 JEA（Just Enough Administration）或自定义端点配置，可以精确控制远程用户能执行哪些命令：

```powershell
# 创建受限会话配置文件
$sessionConfig = @{
    SchemaVersion = '2.0.0.0'
    GUID = (New-Guid).ToString()
    Author = 'Admin'
    Description = '受限运维端点'
    LanguageMode = 'NoLanguage'
    ExecutionPolicy = 'Restricted'
    SessionType = 'RestrictedRemoteServer'
    VisibleCmdlets = @(
        @{ Name = 'Get-Service'; Parameters = @{ Name = 'Name' } },
        @{ Name = 'Get-Process' },
        @{ Name = 'Get-EventLog'; Parameters = @{ Name = 'LogName' }, @{ Name = 'Newest' } }
    )
    VisibleFunctions = @('Get-SystemInfo')
    RoleDefinitions = @{
        'CONTOSO\OpsTeam' = @{ RoleCapabilities = 'MaintenanceRole' }
    }
}

$configPath = "C:\Configs\ConstrainedEndpoint.pssc"
New-PSSessionConfigurationFile -Path $configPath @sessionConfig

# 注册端点
Register-PSSessionConfiguration -Name "OpsEndpoint" -Path $configPath -Force

# 使用受限端点连接
$session = New-PSSession -ComputerName SRV01 -ConfigurationName "OpsEndpoint"
Invoke-Command -Session $session -ScriptBlock { Get-Service -Name WinRM }
```

执行结果示例：

```
Status   Name               DisplayName
------   ----               -----------
Running  WinRM              Windows Remote Management (WS-Management)

Name         Description
----         -----------
OpsEndpoint  受限运维端点

Status  Name  DisplayName
------  ----  -----------
Running WinRM Windows Remote Management (WS-Management)
```

## 大规模并行远程操作

当需要同时管理数十或数百台服务器时，需要合理的并行策略来平衡效率和资源消耗：

```powershell
function Invoke-ParallelRemoting {
    <#
    .SYNOPSIS
    批量并行远程执行命令
    #>
    param(
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [int]$ThrottleLimit = 16,
        [int]$TimeoutMinutes = 10
    )

    # 读取服务器列表
    $totalServers = $ComputerName.Count
    Write-Host "共 $totalServers 台服务器需要处理，并发数：$ThrottleLimit" -ForegroundColor Cyan

    $results = @()
    $successCount = 0
    $failCount = 0
    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    # 分批处理
    $batches = [Math]::Ceiling($totalServers / $ThrottleLimit)

    for ($batch = 0; $batch -lt $batches; $batch++) {
        $batchServers = $ComputerName | Select-Object -Skip ($batch * $ThrottleLimit) -First $ThrottleLimit

        Write-Host "`n批次 $($batch + 1)/$batches ($($batchServers.Count) 台)..." -ForegroundColor Yellow

        $batchResults = Invoke-Command -ComputerName $batchServers `
            -ScriptBlock $ScriptBlock `
            -ThrottleLimit $ThrottleLimit `
            -ErrorAction SilentlyContinue

        foreach ($r in $batchResults) {
            if ($r) {
                $successCount++
                $results += $r
            } else {
                $failCount++
            }
        }
    }

    $sw.Stop()

    Write-Host "`n========== 执行摘要 ==========" -ForegroundColor Green
    Write-Host "总服务器数：$totalServers"
    Write-Host "成功：$successCount"
    Write-Host "失败：$failCount"
    Write-Host "总耗时：$($sw.Elapsed.TotalSeconds) 秒"
    Write-Host "平均每台：$([math]::Round($sw.Elapsed.TotalSeconds / $totalServers, 2)) 秒"

    return $results
}

# 示例：批量检查服务器补丁状态
$computers = Get-Content "C:\Servers.txt"
$results = Invoke-ParallelRemoting -ComputerName $computers -ScriptBlock {
    $os = Get-CimInstance Win32_OperatingSystem
    $latestPatch = Get-CimInstance Win32_QuickFixEngineering |
        Sort-Object InstalledOn -Descending | Select-Object -First 1

    [PSCustomObject]@{
        Computer   = $env:COMPUTERNAME
        OS         = $os.Caption
        LastPatch  = $latestPatch.InstalledOn.ToString('yyyy-MM-dd')
        HotFixID   = $latestPatch.HotFixID
        UptimeDays = [math]::Round(((Get-Date) - $os.LastBootUpTime).TotalDays, 1)
    }
}

$results | Sort-Computer | Format-Table -AutoSize
```

执行结果示例：

```
共 50 台服务器需要处理，并发数：16

批次 1/4 (16 台)...
批次 2/4 (16 台)...
批次 3/4 (16 台)...
批次 4/4 (2 台)...

========== 执行摘要 ==========
总服务器数：50
成功：48
失败：2
总耗时：23.45 秒
平均每台：0.47 秒

Computer   OS                           LastPatch  HotFixID   UptimeDays
--------   --                           ---------  --------   ----------
SRV01      Microsoft Windows Server ... 2025-05-10 KB5036908  2.1
SRV02      Microsoft Windows Server ... 2025-04-28 KB5034441  14.3
SRV03      Microsoft Windows Server ... 2025-05-05 KB5035849  7.0
```

## 远程文件传输

通过 PowerShell 远程会话，可以在本地和远程机器之间传输文件：

```powershell
# 方法一：使用 Copy-Item 与会话
$session = New-PSSession -ComputerName SRV01

# 上传文件到远程
Copy-Item -Path "C:\Scripts\Deploy-App.ps1" `
    -Destination "C:\Scripts\" `
    -ToSession $session

# 从远程下载文件
Copy-Item -Path "C:\Logs\app.log" `
    -Destination "C:\Downloads\SRV01-app.log" `
    -FromSession $session

# 方法二：传输整个目录
Copy-Item -Path "C:\Projects\MyApp\" `
    -Destination "C:\Apps\MyApp\" `
    -ToSession $session -Recurse

# 方法三：传输前压缩（适合大量小文件）
Compress-Archive -Path "C:\Projects\MyApp\*" -DestinationPath "C:\Temp\app.zip"
Copy-Item -Path "C:\Temp\app.zip" -Destination "C:\Temp\" -ToSession $session
Invoke-Command -Session $session -ScriptBlock {
    Expand-Archive -Path "C:\Temp\app.zip" -DestinationPath "C:\Apps\MyApp" -Force
    Remove-Item "C:\Temp\app.zip"
}

Remove-PSSession $session
```

执行结果示例：

```
# 文件传输无输出，成功即完成
```

## 注意事项

1. **双跃点认证**：从 A 机器远程到 B 机器，再从 B 访问 C 机器的资源时，默认凭据不会传递。需要配置 CredSSP 或使用 Kerberos 委派
2. **WinRM 端口**：HTTP 默认端口 5985，HTTPS 默认端口 5986。生产环境建议使用 HTTPS
3. **会话清理**：长时间运行的脚本应确保在 `finally` 块中清理 `PSSession`，避免会话泄漏
4. **序列化限制**：远程命令返回的对象会被序列化/反序列化，某些类型（如 `FileStream`）无法直接返回，需要在远程端处理
5. **并发限制**：默认 WinRM 每个用户最多 5 个并发 shell，可通过 `MaxShellsPerUser` 调整
6. **网络超时**：`New-PSSession` 默认操作超时 3 分钟，可通过 `-OperationTimeoutSeconds` 调整
