---
layout: post
date: 2025-05-26 08:00:00
updated: 2025-05-26 08:00:00
title: "PowerShell 技能连载 - 定时任务与计划任务"
description: PowerTip of the Day - Scheduled Tasks in PowerShell
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

_适用于 PowerShell 5.1 及以上版本（Windows）_

自动化运维的核心是定时执行——每天凌晨备份数据库、每周清理临时文件、每小时检查服务状态、每月生成报表。Windows 计划任务（Task Scheduler）是实现定时执行的基础设施，而 PowerShell 的 `ScheduledTasks` 模块提供了完整的计划任务管理能力，可以替代传统的 GUI 操作和 `schtasks.exe` 命令行工具。

本文将讲解计划任务的创建、管理、高级触发器配置，以及常见的自动化任务模板。

<!-- more -->

## 基础任务管理

使用 `ScheduledTasks` 模块管理计划任务：

```powershell
# 导入模块（Windows 8/Server 2012+ 内置）
Import-Module ScheduledTasks

# 查看所有计划任务
Get-ScheduledTask | Where-Object State -ne 'Disabled' |
    Select-Object TaskName, TaskPath, State |
    Sort-Object TaskName |
    Format-Table -AutoSize

# 查看特定任务详情
$task = Get-ScheduledTask -TaskName "MyBackupTask"
$task | Select-Object TaskName, State, Description
$task.Triggers | Format-List
$task.Actions | Format-List

# 查看任务运行历史
Get-ScheduledTaskInfo -TaskName "MyBackupTask" |
    Select-Object TaskName, LastRunTime, LastTaskResult,
        NextRunTime, NumberOfMissedRuns |
    Format-List

# 启用/禁用任务
Enable-ScheduledTask -TaskName "MyBackupTask"
Disable-ScheduledTask -TaskName "MyBackupTask"

# 手动启动任务
Start-ScheduledTask -TaskName "MyBackupTask"
```

执行结果示例：

```
TaskName              TaskPath           State
--------              --------           -----
MyBackupTask          \CustomTasks\      Ready
GoogleUpdateTask      \Google\           Ready
OneDrive Reporting    \Microsoft\        Running

TaskName     : MyBackupTask
State        : Ready
Description  : 每日数据库备份

LastRunTime      : 2025-05-26 02:00:00
LastTaskResult   : 0
NextRunTime      : 2025-05-27 02:00:00
NumberOfMissedRuns: 0
```

## 创建基本计划任务

创建计划任务需要三个核心组件：触发器（何时运行）、操作（运行什么）和设置（运行条件）：

```powershell
# 创建每日备份任务
$action = New-ScheduledTaskAction `
    -Execute "PowerShell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File C:\Scripts\Backup-Database.ps1" `
    -WorkingDirectory "C:\Scripts"

$trigger = New-ScheduledTaskTrigger -Daily -At "02:00AM"

$settings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -DontStopOnIdleEnd `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -ExecutionTimeLimit (New-TimeSpan -Hours 4)

$taskParams = @{
    TaskName    = "Daily-Database-Backup"
    TaskPath    = "\CustomTasks\"
    Action      = $action
    Trigger     = $trigger
    Settings    = $settings
    Description = "每日凌晨 2 点执行数据库备份"
    RunLevel    = "Highest"
    User        = "SYSTEM"
}

Register-ScheduledTask @taskParams -Force
Write-Host "计划任务已创建：Daily-Database-Backup" -ForegroundColor Green
```

执行结果示例：

```
TaskName              TaskPath           State
--------              --------           -----
Daily-Database-Backup \CustomTasks\      Ready
```

> **注意**：`-RunLevel Highest` 表示以最高权限运行。如果任务需要管理员权限，使用 SYSTEM 账户或指定管理员账户。

## 多种触发器类型

计划任务支持多种触发器，可以满足复杂的调度需求：

```powershell
# 每周触发（周一至周五）
$weekdayTrigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday,Tuesday,Wednesday,Thursday,Friday -At "06:00AM"

# 每月触发（每月 1 日和 15 日）
$monthlyTrigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At "09:00AM"
# 注意：PowerShell 的 New-ScheduledTaskTrigger 不直接支持每月特定日期
# 需要通过 XML 或 COM 对象配置

# 使用 COM 对象创建每月触发器
$taskService = New-Object -ComObject Schedule.Service
$taskService.Connect()
$taskFolder = $taskService.GetFolder("\")
$taskDef = $taskService.NewTask(0)

$monthlyTrigger = $taskDef.Triggers.Create(4)  # 4 = Monthly trigger
$monthlyTrigger.DaysOfMonth = 1 -bor 15  # 1 日和 15 日
$monthlyTrigger.MonthsOfYear = 0xFFF  # 所有月份
$monthlyTrigger.StartBoundary = "2025-01-01T09:00:00"
$monthlyTrigger.Enabled = $true

# 启动时触发
$bootTrigger = New-ScheduledTaskTrigger -AtStartup

# 用户登录时触发
$logonTrigger = New-ScheduledTaskTrigger -AtLogOn

# 一次性触发
$onceTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddHours(2)

# 重复触发（每 15 分钟一次，持续 1 天）
$repeatTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date) `
    -RepetitionInterval (New-TimeSpan -Minutes 15) `
    -RepetitionDuration (New-TimeSpan -Days 1)
```

执行结果示例：

```
# 触发器创建无输出，需注册后查看
```

## 常见自动化任务模板

以下是几个实用的计划任务模板：

```powershell
# 模板一：每日清理临时文件
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-NoProfile -Command `
        `Get-ChildItem 'C:\Temp' -Recurse -File | `
        Where-Object { `$_.LastWriteTime -lt (Get-Date).AddDays(-7) } | `
        Remove-Item -Force -Recurse`"

Register-ScheduledTask -TaskName "Cleanup-TempFiles" `
    -TaskPath "\CustomTasks\" `
    -Action $action `
    -Trigger (New-ScheduledTaskTrigger -Daily -At "03:00AM") `
    -Settings (New-ScheduledTaskSettingsSet -StartWhenAvailable) `
    -User "SYSTEM" -RunLevel Highest -Force

# 模板二：每周检查磁盘空间并发邮件
$diskCheckScript = @'
    $threshold = 10  # GB
    $disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
    $lowSpace = $disks | Where-Object { ($_.FreeSpace / 1GB) -lt $threshold }

    if ($lowSpace) {
        $body = $lowSpace | ForEach-Object {
            "驱动器 $($_.DeviceID) 可用空间：$([math]::Round($_.FreeSpace/1GB, 2)) GB"
        }
        Send-MailMessage -To "admin@contoso.com" -From "monitor@contoso.com" `
            -Subject "磁盘空间告警" -Body ($body -join "`n") `
            -SmtpServer "mail.contoso.com"
    }
'@

Set-Content -Path "C:\Scripts\Check-DiskSpace.ps1" -Value $diskCheckScript

$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-NoProfile -File C:\Scripts\Check-DiskSpace.ps1"

Register-ScheduledTask -TaskName "Weekly-DiskSpace-Check" `
    -TaskPath "\CustomTasks\" `
    -Action $action `
    -Trigger (New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At "08:00AM") `
    -User "SYSTEM" -RunLevel Highest -Force

# 模板三：每小时检查服务状态
$serviceCheckScript = @'
    $services = @('W3SVC', 'MSSQLSERVER', 'WinRM')
    foreach ($svc in $services) {
        $status = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if ($status -and $status.Status -ne 'Running') {
            Write-Warning "服务 $svc 状态异常：$($status.Status)"
            # 可以添加自动重启逻辑
            Start-Service -Name $svc -ErrorAction SilentlyContinue
        }
    }
'@

Set-Content -Path "C:\Scripts\Check-Services.ps1" -Value $serviceCheckScript

$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-NoProfile -File C:\Scripts\Check-Services.ps1"

$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) `
    -RepetitionInterval (New-TimeSpan -Hours 1) `
    -RepetitionDuration (New-TimeSpan -Days 365)

Register-ScheduledTask -TaskName "Hourly-Service-Check" `
    -TaskPath "\CustomTasks\" `
    -Action $action `
    -Trigger $trigger `
    -Settings (New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries) `
    -User "SYSTEM" -RunLevel Highest -Force

Write-Host "所有计划任务已创建" -ForegroundColor Green
```

执行结果示例：

```
所有计划任务已创建
```

## 批量部署计划任务

在多台服务器上部署相同的计划任务：

```powershell
function Deploy-ScheduledTask {
    <#
    .SYNOPSIS
    在远程服务器上部署计划任务
    #>
    param(
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [string]$ScriptPath = "C:\Scripts\Check-Services.ps1",
        [string]$TaskName = "Service-Monitor"
    )

    foreach ($computer in $ComputerName) {
        Write-Host "部署到：$computer" -ForegroundColor Cyan

        # 复制脚本到远程
        $session = New-PSSession -ComputerName $computer
        Copy-Item -Path $ScriptPath -Destination "C:\Scripts\" -ToSession $session -Force

        # 在远程创建计划任务
        Invoke-Command -Session $session -ScriptBlock {
            param($taskName, $scriptPath)

            $action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
                -Argument "-NoProfile -File $scriptPath"

            $trigger = New-ScheduledTaskTrigger -Daily -At "06:00AM"
            $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable

            Register-ScheduledTask -TaskName $taskName `
                -Action $action -Trigger $trigger -Settings $settings `
                -User "SYSTEM" -RunLevel Highest -Force | Out-Null

            Write-Host "  已注册任务：$taskName" -ForegroundColor Green
        } -ArgumentList $TaskName, "C:\Scripts\$(Split-Path $ScriptPath -Leaf)"

        Remove-PSSession $session
    }
}

# 部署到所有 Web 服务器
Deploy-ScheduledTask -ComputerName @('SRV-WEB01', 'SRV-WEB02', 'SRV-WEB03') `
    -TaskName "Service-Monitor"
```

执行结果示例：

```
部署到：SRV-WEB01
  已注册任务：Service-Monitor
部署到：SRV-WEB02
  已注册任务：Service-Monitor
部署到：SRV-WEB03
  已注册任务：Service-Monitor
```

## 注意事项

1. **执行策略**：计划任务中运行 PowerShell 脚本时，使用 `-ExecutionPolicy Bypass` 参数绕过执行策略限制
2. **路径使用绝对路径**：计划任务的工作目录可能与交互式会话不同，始终使用绝对路径
3. **SYSTEM 账户限制**：SYSTEM 账户没有网络访问权限，需要访问网络资源时应使用 gMSA 或服务账户
4. **超时设置**：为长时间运行的任务设置合理的 `ExecutionTimeLimit`，避免任务无限挂起
5. **日志记录**：计划任务中的脚本应将输出写入日志文件，便于排查问题
6. **错过执行处理**：`-StartWhenAvailable` 设置确保因关机等原因错过的任务在下次启动时补执行
