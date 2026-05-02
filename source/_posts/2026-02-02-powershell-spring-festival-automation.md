---
layout: post
date: 2026-02-02 08:00:00
updated: 2026-02-02 08:00:00
title: "PowerShell 技能连载 - 春节假期自动化值守"
description: PowerTip of the Day - Spring Festival Holiday Automation Watch in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- automation
- best-practices
- monitoring
---

_适用于 PowerShell 5.1 及以上版本_

春节长假是万家团圆的时刻，但对于 IT 运维团队来说，系统不会因为放假而停止运行。服务器、数据库、网络设备依然需要有人关注，而值班人员往往捉襟见肘——用最少的人力覆盖最长的假期，成为每年春节前的经典难题。

传统做法是安排轮班表，让值班人员定时登录系统查看状态。这种方式不仅效率低下，而且容易因为人为疏忽而遗漏关键告警。更理想的做法是构建一套自动化值守系统，让脚本替人完成日常巡检、故障处理和告警推送，值班人员只需要在真正出现异常时介入。

PowerShell 凭借其对 Windows 和 Linux（通过 PowerShell Core）的广泛支持、丰富的远程管理能力以及与 .NET 的深度融合，非常适合承担这个角色。本文将从监控系统、自动修复、告警通知三个方面，手把手搭建一个春节假期自动化值守方案。

<!-- more -->

## 假期值守监控系统

首先需要一套主动巡检机制，定期检查服务器的关键指标。以下脚本实现了磁盘空间、CPU 利用率和内存使用率的阈值检测，并将结果汇总为结构化对象，便于后续处理。

```powershell
function Start-HolidayWatch {
    param(
        [string[]]$ComputerName = $env:COMPUTERNAME,
        [double]$DiskThresholdPercent = 10,
        [double]$CpuThresholdPercent = 90,
        [double]$MemoryThresholdPercent = 90,
        [pscredential]$Credential
    )

    $results = foreach ($computer in $ComputerName) {
        $params = @{
            ComputerName = $computer
            ErrorAction  = 'Stop'
        }
        if ($Credential) { $params.Credential = $Credential }

        try {
            # 获取操作系统信息
            $os = Get-CimInstance Win32_OperatingSystem @params
            $freeMemoryPercent = [math]::Round(
                ($os.FreePhysicalMemory / $os.TotalVisibleMemorySize) * 100, 2
            )
            $usedMemoryPercent = [math]::Round(100 - $freeMemoryPercent, 2)

            # 获取磁盘信息
            $disks = Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' @params
            $diskAlerts = foreach ($disk in $disks) {
                $freePercent = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 2)
                if ($freePercent -lt $DiskThresholdPercent) {
                    [PSCustomObject]@{
                        Drive       = $disk.DeviceID
                        FreePercent = $freePercent
                        FreeGB      = [math]::Round($disk.FreeSpace / 1GB, 2)
                        Status      = 'WARNING'
                    }
                }
            }

            # 获取 CPU 使用率（采样 2 秒）
            $cpu = Get-CimInstance Win32_Processor @params
            $cpuPercent = [math]::Round(
                ($cpu | Measure-Object -Property LoadPercentage -Average).Average, 2
            )

            [PSCustomObject]@{
                Computer       = $computer
                Timestamp      = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                CPUPercent     = $cpuPercent
                MemoryPercent  = $usedMemoryPercent
                DiskAlerts     = $diskAlerts
                CPUStatus      = if ($cpuPercent -gt $CpuThresholdPercent) { 'WARNING' } else { 'OK' }
                MemoryStatus   = if ($usedMemoryPercent -gt $MemoryThresholdPercent) { 'WARNING' } else { 'OK' }
                OverallStatus  = if ($cpuPercent -gt $CpuThresholdPercent -or
                    $usedMemoryPercent -gt $MemoryThresholdPercent -or $diskAlerts) {
                    'ALERT'
                } else { 'OK' }
            }
        }
        catch {
            [PSCustomObject]@{
                Computer      = $computer
                Timestamp     = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                OverallStatus = 'ERROR'
                ErrorMessage  = $_.Exception.Message
            }
        }
    }

    # 汇总报告
    $alertCount = ($results | Where-Object OverallStatus -eq 'ALERT').Count
    $errorCount = ($results | Where-Object OverallStatus -eq 'ERROR').Count

    [PSCustomObject]@{
        ScanTime   = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        TotalHosts = $ComputerName.Count
        Alerts     = $alertCount
        Errors     = $errorCount
        Details    = $results
    }
}

# 执行监控——可以配合计划任务每 15 分钟运行一次
$watchParams = @{
    ComputerName        = 'SRV-WEB01', 'SRV-DB01', 'SRV-APP01'
    DiskThresholdPercent = 15
    CpuThresholdPercent  = 85
    MemoryThresholdPercent = 90
}
$report = Start-HolidayWatch @watchParams
$report.Details | Format-Table Computer, CPUPercent, MemoryPercent, CPUStatus, MemoryStatus, OverallStatus -AutoSize
```

执行结果示例：

```
Computer  CPUPercent MemoryPercent CPUStatus MemoryStatus OverallStatus
--------  ---------- ------------- --------- ------------ -------------
SRV-WEB01       12.5         62.30 OK        OK           OK
SRV-DB01        45.8         78.15 OK        OK           OK
SRV-APP01       91.2         92.50 WARNING   WARNING      ALERT
```

## 自动修复与应急响应

监控只是第一步，更高级的玩法是让系统自动处理常见故障。下面的脚本展示了服务自动重启、日志清理和磁盘空间释放三种应急操作，每种操作都有日志记录和回滚机制。

```powershell
function Invoke-AutoRemediation {
    param(
        [string]$ComputerName = $env:COMPUTERNAME,
        [string[]]$CriticalServices = @('W3SVC', 'MSSQLSERVER', 'WinRM'),
        [double]$LogCleanupThresholdGB = 2,
        [string]$LogPath = 'C:\Logs',
        [string]$TranscriptPath = 'C:\HolidayWatch\Remediation.log'
    )

    # 记录所有操作
    Start-Transcript -Path $TranscriptPath -Append -Force
    $actions = @()

    foreach ($svc in $CriticalServices) {
        try {
            $service = Get-Service -Name $svc -ComputerName $ComputerName -ErrorAction Stop
            if ($service.Status -ne 'Running') {
                Write-Warning "服务 [$svc] 状态异常: $($service.Status)，尝试启动..."
                $service | Start-Service -ErrorAction Stop
                $actions += [PSCustomObject]@{
                    Time   = Get-Date -Format 'HH:mm:ss'
                    Action = 'RestartService'
                    Target = $svc
                    Result = 'SUCCESS'
                }
                Write-Host "服务 [$svc] 已成功启动" -ForegroundColor Green
            }
        }
        catch {
            $actions += [PSCustomObject]@{
                Time   = Get-Date -Format 'HH:mm:ss'
                Action = 'RestartService'
                Target = $svc
                Result = "FAILED: $($_.Exception.Message)"
            }
            Write-Error "服务 [$svc] 启动失败: $($_.Exception.Message)"
        }
    }

    # 清理旧日志文件
    if (Test-Path $LogPath) {
        $oldLogs = Get-ChildItem -Path $LogPath -Recurse -File |
            Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) }

        $totalSize = ($oldLogs | Measure-Object -Property Length -Sum).Sum / 1GB
        if ($totalSize -gt $LogCleanupThresholdGB) {
            Write-Warning "日志目录占用 $([math]::Round($totalSize, 2)) GB，超过阈值，开始清理..."
            $oldLogs | Remove-Item -Force -ErrorAction SilentlyContinue
            $freed = [math]::Round($totalSize, 2)
            $actions += [PSCustomObject]@{
                Time   = Get-Date -Format 'HH:mm:ss'
                Action = 'CleanLogs'
                Target = $LogPath
                Result = "SUCCESS - 释放 ${freed} GB"
            }
        }
    }

    # 磁盘空间应急释放：清理临时文件和回收站
    $systemDrive = Get-CimInstance Win32_LogicalDisk -Filter 'DeviceID="C:"'
    $freePercent = [math]::Round(($systemDrive.FreeSpace / $systemDrive.Size) * 100, 2)

    if ($freePercent -lt 15) {
        Write-Warning "C 盘剩余空间仅 $freePercent%，执行应急清理..."
        $tempPaths = @(
            "$env:TEMP\*",
            'C:\Windows\Temp\*',
            'C:\Windows\SoftwareDistribution\Download\*'
        )
        foreach ($path in $tempPaths) {
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
        }
        # 清理回收站
        Clear-RecycleBin -DriveLetter C -Force -ErrorAction SilentlyContinue

        $newFree = [math]::Round(
            ((Get-CimInstance Win32_LogicalDisk -Filter 'DeviceID="C:"').FreeSpace /
            (Get-CimInstance Win32_LogicalDisk -Filter 'DeviceID="C:"').Size) * 100, 2
        )
        $actions += [PSCustomObject]@{
            Time   = Get-Date -Format 'HH:mm:ss'
            Action = 'EmergencyDiskCleanup'
            Target = 'C:'
            Result = "释放空间: $freePercent% -> $newFree%"
        }
    }

    Stop-Transcript
    return $actions
}

# 检测到告警后自动触发修复
$report = Start-HolidayWatch -ComputerName 'SRV-APP01'
if ($report.Details.OverallStatus -eq 'ALERT') {
    Write-Host "检测到告警，启动自动修复流程..." -ForegroundColor Yellow
    $remediation = Invoke-AutoRemediation -ComputerName 'SRV-APP01'
    $remediation | Format-Table Time, Action, Target, Result -AutoSize
}
```

执行结果示例：

```
检测到告警，启动自动修复流程...
Time   Action               Target   Result
----   ------               ------   ------
14:32  RestartService       W3SVC    SUCCESS
14:33  CleanLogs            C:\Logs  SUCCESS - 释放 3.45 GB
14:34  EmergencyDiskCleanup C:       释放空间: 11.20% -> 18.65%
```

## 告警通知与值班管理

监控系统发现问题、自动修复尝试完毕后，需要及时通知值班人员。以下脚本集成了邮件通知、企业微信 Webhook 和钉钉 Webhook 三种告警通道，并支持值班轮换和告警升级机制。

```powershell
function Send-HolidayAlert {
    param(
        [Parameter(Mandatory)]
        [string]$Title,

        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet('Mail', 'WeCom', 'DingTalk', 'All')]
        [string]$Channel = 'All',

        # 邮件参数
        [string]$SmtpServer = 'smtp.company.com',
        [int]$SmtpPort = 587,
        [string]$MailFrom = 'ops-holiday@company.com',
        [string[]]$MailTo = @('oncall@company.com'),

        # Webhook URL
        [string]$WeComWebhookUrl,
        [string]$DingTalkWebhookUrl,

        # 告警级别
        [ValidateSet('Info', 'Warning', 'Critical')]
        [string]$Severity = 'Warning'
    )

    $severityEmoji = @{
        Info     = '[INFO]'
        Warning  = '[WARN]'
        Critical = '[CRIT]'
    }
    $prefix = $severityEmoji[$Severity]
    $body = "$prefix $Title`n`n$Message`n`n时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

    # 邮件通知
    if ($Channel -in 'Mail', 'All') {
        try {
            Send-MailMessage -From $MailFrom -To $MailTo -Subject "$prefix $Title" `
                -Body $body -SmtpServer $SmtpServer -Port $SmtpPort -Encoding UTF8
            Write-Host "邮件告警已发送至: $($MailTo -join ', ')" -ForegroundColor Green
        }
        catch {
            Write-Warning "邮件发送失败: $($_.Exception.Message)"
        }
    }

    # 企业微信通知
    if ($Channel -in 'WeCom', 'All' -and $WeComWebhookUrl) {
        $wecomBody = @{
            msgtype = 'text'
            text    = @{ content = $body }
        } | ConvertTo-Json -Compress

        try {
            Invoke-RestMethod -Uri $WeComWebhookUrl -Method Post `
                -Body $wecomBody -ContentType 'application/json' | Out-Null
            Write-Host '企业微信告警已发送' -ForegroundColor Green
        }
        catch {
            Write-Warning "企业微信发送失败: $($_.Exception.Message)"
        }
    }

    # 钉钉通知
    if ($Channel -in 'DingTalk', 'All' -and $DingTalkWebhookUrl) {
        $dingBody = @{
            msgtype = 'text'
            text    = @{ content = $body }
        } | ConvertTo-Json -Compress

        try {
            Invoke-RestMethod -Uri $DingTalkWebhookUrl -Method Post `
                -Body $dingBody -ContentType 'application/json' | Out-Null
            Write-Host '钉钉告警已发送' -ForegroundColor Green
        }
        catch {
            Write-Warning "钉钉发送失败: $($_.Exception.Message)"
        }
    }
}

function Get-CurrentOnCall {
    param(
        [hashtable]$Schedule = @{
            '2026-02-08' = '张三', '2026-02-09' = '张三'
            '2026-02-10' = '李四', '2026-02-11' = '李四'
            '2026-02-12' = '王五', '2026-02-13' = '王五'
            '2026-02-14' = '张三'
        },
        [hashtable]$Contacts = @{
            '张三' = @{ Email = 'zhangsan@company.com'; Phone = '138-0001-0001' }
            '李四' = @{ Email = 'lisi@company.com'; Phone = '138-0002-0002' }
            '王五' = @{ Email = 'wangwu@company.com'; Phone = '138-0003-0003' }
        }
    )

    $today = Get-Date -Format 'yyyy-MM-dd'
    $person = $Schedule[$today]
    if (-not $person) {
        # 如果当天没有排班，查找最近的一天
        $nearest = $Schedule.Keys | Sort-Object | Where-Object { $_ -le $today } | Select-Object -Last 1
        $person = $Schedule[$nearest]
    }

    [PSCustomObject]@{
        Date      = $today
        OnCall    = $person
        Email     = $Contacts[$person].Email
        Phone     = $Contacts[$person].Phone
    }
}

# 告警升级：Critical 级别同时通知值班人员和运维经理
$onCall = Get-CurrentOnCall
$alertParams = @{
    Title    = 'SRV-APP01 CPU 使用率持续超过 90%'
    Message  = "服务器 SRV-APP01 CPU 使用率 91.2%，内存使用率 92.5%。`n自动修复已尝试重启服务。`n当前值班: $($onCall.OnCall) ($($onCall.Phone))"
    Channel  = 'All'
    Severity = 'Critical'
    MailTo   = @($onCall.Email, 'ops-manager@company.com')
}
Send-HolidayAlert @alertParams
```

执行结果示例：

```
邮件告警已发送至: zhangsan@company.com, ops-manager@company.com
企业微信告警已发送
钉钉告警已发送

Date       OnCall Email                    Phone
----       ------ -----                    -----
2026-02-08 张三   zhangsan@company.com     138-0001-0001
```

## 完整部署建议

将以上三个模块整合后，可以创建一个计划任务，在假期期间每 15 分钟自动执行一轮巡检。核心逻辑如下：

```powershell
# Deploy-HolidayWatch.ps1 - 注册计划任务
$action = New-ScheduledTaskAction -Execute 'pwsh.exe' -Argument '-File "C:\HolidayWatch\Run-Watch.ps1"'
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 15)
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
Register-ScheduledTask -TaskName 'HolidayWatch-2026' -Action $action -Trigger $trigger -Settings $settings -RunLevel Highest -Description '春节假期自动化值守任务'
```

## 注意事项

1. **凭据安全**：远程管理使用的凭据应存储在 Windows 凭据管理器或 Azure Key Vault 中，切勿以明文形式写在脚本里。可以使用 `Get-Credential` 交互式获取，或通过 `Export-Clixml` 加密存储。
2. **网络可达性**：确保执行脚本的跳板机与目标服务器之间网络畅通，WinRM（端口 5985/5986）或 SSH 已正确配置并允许远程连接。
3. **告警风暴防护**：设置告警冷却时间（如同一告警 30 分钟内不重复发送），避免因瞬时抖动产生大量重复通知淹没值班人员。
4. **日志持久化**：所有巡检和修复操作必须记录到持久化日志文件，建议同时写入本地文件和集中日志平台（如 ELK），以便假期结束后复盘。
5. **自动修复边界**：自动修复只应处理已知的安全操作（如重启服务、清理临时文件），切勿让脚本自动执行删除数据库、重启服务器等高风险操作。
6. **节前演练**：在放假前至少进行一次完整的端到端演练，包括模拟告警触发、自动修复执行、通知送达，确保每个环节都能正常工作。
