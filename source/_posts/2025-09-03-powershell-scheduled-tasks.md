---
layout: post
date: 2025-09-03 08:00:00
updated: 2025-09-03 08:00:00
title: "PowerShell 技能连载 - 计划任务管理"
description: PowerTip of the Day - Scheduled Task Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- scheduled-tasks
- task-scheduler
- automation
---

_适用于 PowerShell 5.1 及以上版本（Windows），部分操作需要管理员权限_

Windows 计划任务（Task Scheduler）是自动化运维的基石，系统维护脚本、定时备份、健康检查、日志清理等都依赖它来定时执行。在早期，管理计划任务需要使用 `schtasks.exe` 命令行工具，参数繁多且语法晦涩。PowerShell 3.0 引入了 `ScheduledTasks` 模块，提供了面向对象的任务管理方式，可以精确控制触发条件、执行账户、重试策略等高级配置。

本文将介绍计划任务的创建、管理和监控自动化。

## 任务创建与配置

```powershell
# 创建基本计划任务
$action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File C:\Scripts\DailyBackup.ps1"

$trigger = New-ScheduledTaskTrigger -Daily -At "02:00"

$settings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -DontStopOnIdleEnd `
    -ExecutionTimeLimit (New-TimeSpan -Hours 2) `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 5)

$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName "DailyBackup" `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Principal $principal `
    -Description "每日凌晨 2:00 执行数据库备份"

Write-Host "已创建计划任务：DailyBackup" -ForegroundColor Green

# 创建多触发器任务
$actions = @(
    New-ScheduledTaskAction -Execute "powershell.exe" `
        -Argument "-NoProfile -File C:\Scripts\HealthCheck.ps1"
)

$triggers = @(
    (New-ScheduledTaskTrigger -Daily -At "06:00")
    (New-ScheduledTaskTrigger -AtStartup)
)

Register-ScheduledTask -TaskName "ServerHealthCheck" `
    -Action $actions `
    -Trigger $triggers `
    -Settings $settings `
    -Principal $principal `
    -Description "每日 6:00 及开机时检查服务器健康状态"

Write-Host "已创建计划任务：ServerHealthCheck" -ForegroundColor Green

# 创建每周任务
$weeklyTrigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "03:00"
Register-ScheduledTask -TaskName "WeeklyReport" `
    -Action (New-ScheduledTaskAction -Execute "powershell.exe" `
        -Argument "-NoProfile -File C:\Scripts\WeeklyReport.ps1") `
    -Trigger $weeklyTrigger `
    -Principal $principal `
    -Description "每周日凌晨 3:00 生成周报"

Write-Host "已创建计划任务：WeeklyReport" -ForegroundColor Green
```

执行结果示例：

```
已创建计划任务：DailyBackup
已创建计划任务：ServerHealthCheck
已创建计划任务：WeeklyReport
```

## 任务查询与监控

```powershell
# 查询所有计划任务
$tasks = Get-ScheduledTask | Where-Object {
    $_.TaskPath -notlike "\Microsoft\*" -and $_.State -ne "Disabled"
}

$tasks | Select-Object TaskName, State,
    @{N='LastRun'; E={ ($_. | Get-ScheduledTaskInfo).LastRunTime.ToString('yyyy-MM-dd HH:mm:ss') }},
    @{N='LastResult'; E={ ($_. | Get-ScheduledTaskInfo).LastTaskResult }},
    @{N='NextRun'; E={ ($_. | Get-ScheduledTaskInfo).NextRunTime.ToString('yyyy-MM-dd HH:mm:ss') }} |
    Format-Table -AutoSize

# 查询失败的任务
$failed = Get-ScheduledTask | ForEach-Object {
    $info = $_ | Get-ScheduledTaskInfo
    if ($info.LastTaskResult -ne 0 -and $_.State -ne "Disabled") {
        [PSCustomObject]@{
            TaskName    = $_.TaskName
            State       = $_.State
            LastRun     = $info.LastRunTime.ToString('yyyy-MM-dd HH:mm:ss')
            ResultCode  = $info.LastTaskResult
            Description = $_.Description
        }
    }
}

if ($failed) {
    Write-Host "发现失败的任务：" -ForegroundColor Red
    $failed | Format-Table -AutoSize
} else {
    Write-Host "所有任务执行正常" -ForegroundColor Green
}

# 任务运行时间统计
Get-ScheduledTask | Where-Object { $_.TaskPath -notlike "\Microsoft\*" } |
    ForEach-Object {
        $info = $_ | Get-ScheduledTaskInfo
        [PSCustomObject]@{
            TaskName = $_.TaskName
            LastRun  = $info.LastRunTime
            NextRun  = $info.NextRunTime
        }
    } | Sort-Object LastRun -Descending | Format-Table -AutoSize
```

执行结果示例：

```
TaskName           State  LastRun            LastResult NextRun
--------           -----  -------           ---------- -------
DailyBackup        Ready  2025-09-03 02:00:00          0 2025-09-04 02:00:00
ServerHealthCheck  Ready  2025-09-03 06:00:15          0 2025-09-04 06:00:00
WeeklyReport       Ready  2025-09-01 03:00:00          0 2025-09-08 03:00:00

所有任务执行正常
```

## 批量任务管理

```powershell
# 批量注册计划任务的函数
function Register-MaintenanceTasks {
    param(
        [string]$ScriptsPath = "C:\Scripts",
        [string]$LogFile = "C:\Logs\TaskSetup.log"
    )

    $taskDefs = @(
        @{
            Name        = "DiskCleanup"
            Script      = "DiskCleanup.ps1"
            Schedule    = "Weekly"
            Time        = "03:00"
            Day         = "Saturday"
            Description = "每周六凌晨 3:00 清理磁盘临时文件"
        }
        @{
            Name        = "LogRotation"
            Script      = "LogRotation.ps1"
            Schedule    = "Daily"
            Time        = "00:30"
            Description = "每日凌晨 0:30 轮转日志文件"
        }
        @{
            Name        = "CertExpiryCheck"
            Script      = "CertExpiryCheck.ps1"
            Schedule    = "Daily"
            Time        = "08:00"
            Description = "每日 8:00 检查证书到期情况"
        }
        @{
            Name        = "SecurityScan"
            Script      = "SecurityScan.ps1"
            Schedule    = "Weekly"
            Time        = "04:00"
            Day         = "Sunday"
            Description = "每周日凌晨 4:00 运行安全扫描"
        }
    )

    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd `
        -ExecutionTimeLimit (New-TimeSpan -Hours 1) -RestartCount 2 `
        -RestartInterval (New-TimeSpan -Minutes 10)

    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

    foreach ($def in $taskDefs) {
        $scriptPath = Join-Path $ScriptsPath $def.Script

        if (-not (Test-Path $scriptPath)) {
            Write-Host "脚本不存在：$scriptPath" -ForegroundColor Red
            continue
        }

        $action = New-ScheduledTaskAction -Execute "powershell.exe" `
            -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""

        if ($def.Schedule -eq "Daily") {
            $trigger = New-ScheduledTaskTrigger -Daily -At $def.Time
        } else {
            $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $def.Day -At $def.Time
        }

        # 检查任务是否已存在
        $existing = Get-ScheduledTask -TaskName $def.Name -ErrorAction SilentlyContinue
        if ($existing) {
            Set-ScheduledTask -TaskName $def.Name -Action $action -Trigger $trigger -Settings $settings
            Write-Host "已更新任务：$($def.Name)" -ForegroundColor Yellow
        } else {
            Register-ScheduledTask -TaskName $def.Name -Action $action `
                -Trigger $trigger -Settings $settings -Principal $principal `
                -Description $def.Description
            Write-Host "已创建任务：$($def.Name)" -ForegroundColor Green
        }

        "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) $($def.Name) registered" | Out-File $LogFile -Append
    }
}

Register-MaintenanceTasks

# 远程服务器批量部署任务
$servers = @("SRV01", "SRV02", "SRV03")

foreach ($server in $servers) {
    try {
        Invoke-Command -ComputerName $server -ScriptBlock {
            $action = New-ScheduledTaskAction -Execute "powershell.exe" `
                -Argument "-NoProfile -File C:\Scripts\HealthCheck.ps1"
            $trigger = New-ScheduledTaskTrigger -Daily -At "06:00"
            $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable

            $existing = Get-ScheduledTask -TaskName "HealthCheck" -ErrorAction SilentlyContinue
            if ($existing) {
                Set-ScheduledTask -TaskName "HealthCheck" -Action $action -Trigger $trigger
            } else {
                Register-ScheduledTask -TaskName "HealthCheck" -Action $action `
                    -Trigger $trigger -Settings $settings `
                    -Principal (New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest)
            }
        } -ErrorAction Stop
        Write-Host "$server ：任务部署成功" -ForegroundColor Green
    } catch {
        Write-Host "$server ：部署失败 - $($_.Exception.Message)" -ForegroundColor Red
    }
}
```

执行结果示例：

```
已创建任务：DiskCleanup
已创建任务：LogRotation
已创建任务：CertExpiryCheck
已创建任务：SecurityScan
SRV01 ：任务部署成功
SRV02 ：任务部署成功
SRV03 ：任务部署成功
```

## 注意事项

1. **执行账户**：SYSTEM 账户无法访问网络资源，需要网络访问的任务应使用 gMSA（组托管服务账户）
2. **执行策略**：脚本文件可能受执行策略限制，任务中使用 `-ExecutionPolicy Bypass` 参数绕过
3. **时区问题**：计划任务的触发时间基于服务器本地时区，分布式部署时注意时区差异
4. **任务超时**：默认执行时间限制为 72 小时，建议根据实际需求设置合理的超时时间
5. **日志记录**：脚本内部应实现日志输出，方便排查任务失败原因
6. **并发冲突**：如果任务可能重叠执行，使用文件锁或数据库锁防止并发冲突
