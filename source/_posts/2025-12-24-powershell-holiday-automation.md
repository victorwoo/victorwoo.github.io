---
layout: post
date: 2025-12-24 08:00:00
updated: 2025-12-24 08:00:00
title: "PowerShell 技能连载 - 节日自动化与年度总结"
description: PowerTip of the Day - Holiday Automation and Year-End Summary in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- reporting
- automation
- best-practices
---

_适用于 PowerShell 5.1 及以上版本_

每到年底，系统管理员面临着大量收尾工作：汇总全年的运维数据、归档陈旧日志、清理过期文件、检查系统健康状态，还要为来年的自动化计划做准备。这些任务如果逐一手动完成，往往要耗费数天时间。而通过 PowerShell 脚本，可以将这些重复性工作编排成可一键执行的自动化流程，大幅缩短收尾周期。

更重要的是，年度总结不仅是对过去一年工作的回顾，更是为来年制定计划的数据基础。通过脚本化汇总，可以确保数据的准确性和一致性——每年生成相同格式的报告，方便横向对比，发现趋势。将枯燥的数据整理交给脚本，管理员才能把精力集中在分析和决策上。

本文将从年度运维数据汇总、数据归档与清理、来年自动化准备三个维度，展示如何用 PowerShell 高效完成年末收尾工作。

<!-- more -->

## 年度运维数据汇总

年终总结的第一步是收集全年的关键运维指标。下面的脚本从 Windows 事件日志、系统运行时间等数据源中提取统计信息，生成一份结构化的年度运维报告。

```powershell
# 年度运维数据汇总脚本
function Get-YearEndOpsSummary {
    param(
        [int]$Year = (Get-Date).Year
    )

    $startDate = Get-Date -Year $Year -Month 1 -Day 1
    $endDate = Get-Date -Year $Year -Month 12 -Day 31 -Hour 23 -Minute 59 -Second 59

    Write-Host "正在汇总 $Year 年度运维数据..." -ForegroundColor Cyan
    Write-Host ("=" * 50)

    # 1. 事件日志统计
    Write-Host "`n[事件日志统计]" -ForegroundColor Yellow

    $logStats = @{}
    $logNames = @('System', 'Application', 'Security')

    foreach ($logName in $logNames) {
        try {
            $events = Get-WinEvent -LogName $logName |
                Where-Object { $_.TimeCreated -ge $startDate -and $_.TimeCreated -le $endDate }

            $logStats[$logName] = [PSCustomObject]@{
                Total     = $events.Count
                Critical  = ($events | Where-Object Level -eq 1).Count
                Error     = ($events | Where-Object Level -eq 2).Count
                Warning   = ($events | Where-Object Level -eq 3).Count
                Information = ($events | Where-Object Level -eq 4).Count
            }
            Write-Host "  $logName : $($logStats[$logName].Total) 条"
        } catch {
            Write-Host "  $logName : 无法读取或无记录" -ForegroundColor DarkGray
        }
    }

    # 2. 服务器可用性统计
    Write-Host "`n[服务器可用性统计]" -ForegroundColor Yellow

    $reboots = Get-WinEvent -LogName System -ErrorAction SilentlyContinue |
        Where-Object {
            $_.TimeCreated -ge $startDate -and $_.TimeCreated -le $endDate -and
            $_.Id -in 1074, 6006, 6008, 41
        }

    $uptimeSpan = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    $totalDaysInYear = ($endDate - $startDate).TotalDays

    # 3. 磁盘使用趋势
    Write-Host "`n[磁盘使用情况]" -ForegroundColor Yellow

    $diskInfo = Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' |
        ForEach-Object {
            $usedGB = [math]::Round(($_.Size - $_.FreeSpace) / 1GB, 2)
            $freeGB = [math]::Round($_.FreeSpace / 1GB, 2)
            $totalGB = [math]::Round($_.Size / 1GB, 2)
            $usedPct = [math]::Round(($usedGB / $totalGB) * 100, 1)

            [PSCustomObject]@{
                Drive   = $_.DeviceID
                UsedGB  = $usedGB
                FreeGB  = $freeGB
                TotalGB = $totalGB
                UsedPct = "$usedPct%"
            }
        }

    $diskInfo | Format-Table -AutoSize

    # 4. 汇总报告对象
    $report = [PSCustomObject]@{
        Year         = $Year
        GeneratedAt  = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        EventLogs    = $logStats
        RebootCount  = $reboots.Count
        CurrentUptime = "$([math]::Floor($uptimeSpan.TotalDays)) 天 $($uptimeSpan.Hours) 小时"
        DiskStatus   = $diskInfo
    }

    # 导出报告
    $reportPath = Join-Path $env:USERPROFILE "Desktop\OpsSummary-$Year.json"
    $report | ConvertTo-Json -Depth 5 | Out-File $reportPath -Encoding UTF8
    Write-Host "`n报告已保存至：$reportPath" -ForegroundColor Green

    return $report
}

# 执行年度汇总
Get-YearEndOpsSummary -Year 2025
```

执行结果示例：

```
正在汇总 2025 年度运维数据...
==================================================

[事件日志统计]
  System : 48256 条
  Application : 31420 条
  Security : 128750 条

[服务器可用性统计]

[磁盘使用情况]
Drive UsedGB FreeGB TotalGB UsedPct
----- ------ ------ ------- -------
C:    186.42  63.58  250.00  74.6%
D:    412.30 587.70 1000.00  41.2%

报告已保存至：C:\Users\admin\Desktop\OpsSummary-2025.json
```

## 数据归档与清理

年度数据归档是运维管理的重要环节。下面的脚本实现了日志压缩打包、过期文件自动清理以及备份完整性验证，帮助管理员在假期前完成数据整理。

```powershell
# 数据归档与清理脚本
function Invoke-YearEndArchive {
    param(
        [string]$ArchiveRoot = "D:\Archives\$(Get-Date -Format 'yyyy')",
        [int]$RetentionDays = 90,
        [string[]]$LogPaths = @(
            "C:\Logs",
            "D:\ApplicationLogs",
            "$env:TEMP"
        ),
        [switch]$WhatIf
    )

    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $archiveDir = Join-Path $ArchiveRoot "Archive-$timestamp"

    if (-not $WhatIf) {
        New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
    }

    Write-Host "=== 年度数据归档与清理 ===" -ForegroundColor Cyan
    Write-Host "归档目录：$archiveDir"
    Write-Host "保留天数：$RetentionDays 天"
    Write-Host ""

    # 1. 日志压缩归档
    Write-Host "[1/3] 压缩归档日志文件..." -ForegroundColor Yellow

    $archiveResults = @()
    foreach ($logPath in $LogPaths) {
        if (-not (Test-Path $logPath)) {
            Write-Host "  跳过（路径不存在）：$logPath" -ForegroundColor DarkGray
            continue
        }

        $logFiles = Get-ChildItem $logPath -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object {
                $_.Extension -in '.log', '.txt', '.csv', '.evtx' -and
                $_.LastWriteTime -lt (Get-Date).AddDays(-$RetentionDays)
            }

        if ($logFiles) {
            $totalSize = [math]::Round(($logFiles | Measure-Object Length -Sum).Sum / 1MB, 2)
            $zipName = "$($logPath -replace '[\\:]', '_')_$timestamp.zip"
            $zipPath = Join-Path $archiveDir $zipName

            if (-not $WhatIf) {
                $logFiles | Compress-Archive -DestinationPath $zipPath -CompressionLevel Optimal
                $zipSize = [math]::Round((Get-Item $zipPath).Length / 1MB, 2)
            } else {
                $zipSize = "N/A (WhatIf)"
            }

            $archiveResults += [PSCustomObject]@{
                Source    = $logPath
                FileCount = $logFiles.Count
                OrigMB    = $totalSize
                ArchiveMB = $zipSize
            }

            Write-Host "  $logPath : $($logFiles.Count) 个文件，${totalSize} MB -> ${zipSize} MB"
        } else {
            Write-Host "  $logPath : 无过期日志" -ForegroundColor DarkGray
        }
    }

    # 2. 过期文件清理
    Write-Host "`n[2/3] 清理过期临时文件..." -ForegroundColor Yellow

    $cleanPatterns = @('*.tmp', '*.temp', '*.bak', '~$*')
    $cleanPaths = @($env:TEMP, "C:\Windows\Temp")
    $cleanedCount = 0
    $cleanedSize = 0

    foreach ($path in $cleanPaths) {
        foreach ($pattern in $cleanPatterns) {
            $files = Get-ChildItem $path -Filter $pattern -Recurse -ErrorAction SilentlyContinue |
                Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) }

            foreach ($file in $files) {
                $cleanedSize += $file.Length
                if (-not $WhatIf) {
                    Remove-Item $file.FullName -Force -ErrorAction SilentlyContinue
                }
                $cleanedCount++
            }
        }
    }

    $cleanedSizeMB = [math]::Round($cleanedSize / 1MB, 2)
    Write-Host "  已清理 $cleanedCount 个临时文件，释放 ${cleanedSizeMB} MB"

    # 3. 备份完整性验证
    Write-Host "`n[3/3] 验证归档完整性..." -ForegroundColor Yellow

    if (-not $WhatIf -and (Test-Path $archiveDir)) {
        $zips = Get-ChildItem $archiveDir -Filter '*.zip'
        foreach ($zip in $zips) {
            try {
                Add-Type -AssemblyName System.IO.Compression.FileSystem
                $archive = [System.IO.Compression.ZipFile]::OpenRead($zip.FullName)
                $entryCount = $archive.Entries.Count
                $archive.Dispose()
                Write-Host "  $($zip.Name) : $entryCount 个文件 - 完整" -ForegroundColor Green
            } catch {
                Write-Host "  $($zip.Name) : 验证失败 - $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }

    Write-Host "`n归档完成！" -ForegroundColor Green
}

# 预览模式（不实际执行）
Invoke-YearEndArchive -WhatIf

# 确认无误后正式执行
# Invoke-YearEndArchive
```

执行结果示例：

```
=== 年度数据归档与清理 ===
归档目录：D:\Archives\2025\Archive-20251224_080000
保留天数：90 天

[1/3] 压缩归档日志文件...
  C:\Logs : 156 个文件，2340.50 MB -> 412.30 MB
  D:\ApplicationLogs : 89 个文件，1580.75 MB -> 298.60 MB
  C:\Users\admin\AppData\Local\Temp : 42 个文件，86.20 MB -> 18.40 MB

[2/3] 清理过期临时文件...
  已清理 327 个临时文件，释放 456.80 MB

[3/3] 验证归档完整性...
  _C_Logs_20251224_080000.zip : 156 个文件 - 完整
  _D_ApplicationLogs_20251224_080000.zip : 89 个文件 - 完整
  _C_Users_admin_AppData_Local_Temp_20251224_080000.zip : 42 个文件 - 完整

归档完成！
```

## 来年自动化准备

假期是审视和优化自动化体系的最佳时机。下面的脚本检查当前计划任务的健康状态、扫描即将到期的证书，并生成一份系统健康检查报告，为来年的运维规划提供数据支撑。

```powershell
# 来年自动化准备脚本
function Invoke-NewYearPreparation {
    param(
        [int]$CertificateWarningDays = 60,
        [string]$ReportPath = "$env:USERPROFILE\Desktop\NewYear-HealthCheck-$(Get-Date -Format 'yyyyMMdd').html"
    )

    Write-Host "=== 来年自动化准备检查 ===" -ForegroundColor Cyan
    Write-Host ""

    # 1. 计划任务健康检查
    Write-Host "[1/3] 检查计划任务..." -ForegroundColor Yellow

    $scheduledTasks = Get-ScheduledTask |
        Where-Object { $_.TaskPath -notlike '\Microsoft\*' } |
        ForEach-Object {
            $info = $_ | Get-ScheduledTaskInfo -ErrorAction SilentlyContinue
            [PSCustomObject]@{
                Name         = $_.TaskName
                Path         = $_.TaskPath
                State        = $_.State
                LastRunTime  = if ($info.LastRunTime -gt '1899-12-30') { $info.LastRunTime } else { '从未运行' }
                LastResult   = $info.LastTaskResult
                NextRunTime  = if ($info.NextRunTime -gt '1899-12-30') { $info.NextRunTime } else { '未计划' }
            }
        }

    $taskStats = @{
        Total    = $scheduledTasks.Count
        Running  = ($scheduledTasks | Where-Object State -eq 'Running').Count
        Ready    = ($scheduledTasks | Where-Object State -eq 'Ready').Count
        Disabled = ($scheduledTasks | Where-Object State -eq 'Disabled').Count
        Failed   = ($scheduledTasks | Where-Object LastResult -ne '0' -and $_.State -eq 'Ready').Count
    }

    Write-Host "  总计：$($taskStats.Total) 个自定义任务"
    Write-Host "  就绪：$($taskStats.Ready) | 运行中：$($taskStats.Running) | 已禁用：$($taskStats.Disabled)"

    # 找出上次执行失败的任务
    $failedTasks = $scheduledTasks |
        Where-Object { $_.LastResult -notin '0', '' -and $_.State -eq 'Ready' }

    if ($failedTasks) {
        Write-Host "`n  上次执行失败的任务：" -ForegroundColor Red
        foreach ($task in $failedTasks) {
            Write-Host "    - $($task.Name) (错误码: $($task.LastResult))" -ForegroundColor Red
        }
    }

    # 2. 证书到期检查
    Write-Host "`n[2/3] 检查证书到期情况..." -ForegroundColor Yellow

    $expiryThreshold = (Get-Date).AddDays($CertificateWarningDays)

    $certExpirations = Get-ChildItem Cert:\LocalMachine\My -ErrorAction SilentlyContinue |
        Where-Object { $_.NotAfter -le $expiryThreshold } |
        Sort-Object NotAfter |
        ForEach-Object {
            $daysLeft = ($_.NotAfter - (Get-Date)).Days
            $status = if ($daysLeft -le 0) { '已过期' }
                      elseif ($daysLeft -le 30) { '紧急' }
                      elseif ($daysLeft -le 60) { '警告' }
                      else { '注意' }

            [PSCustomObject]@{
                Subject   = $_.Subject
                Thumbprint = $_.Thumbprint.Substring(0, 16) + '...'
                Expires   = $_.NotAfter.ToString('yyyy-MM-dd')
                DaysLeft  = $daysLeft
                Status    = $status
            }
        }

    if ($certExpirations) {
        $certExpirations | Format-Table -AutoSize
    } else {
        Write-Host "  未发现即将到期的证书" -ForegroundColor Green
    }

    # 3. 系统健康检查
    Write-Host "`n[3/3] 系统健康检查..." -ForegroundColor Yellow

    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor
    $memTotalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $memFreeGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $memUsedPct = [math]::Round(($memTotalGB - $memFreeGB) / $memTotalGB * 100, 1)
    $cpuLoad = $cpu.LoadPercentage

    $healthReport = [PSCustomObject]@{
        ComputerName   = $env:COMPUTERNAME
        OSVersion      = $os.Caption
        LastBootTime   = $os.LastBootUpTime.ToString('yyyy-MM-dd HH:mm:ss')
        CPULoad        = "$cpuLoad%"
        MemoryTotalGB  = $memTotalGB
        MemoryFreeGB   = $memFreeGB
        MemoryUsedPct  = "$memUsedPct%"
        ServicesFailed = (Get-Service | Where-Object { $_.Status -eq 'Stopped' -and $_.StartType -eq 'Automatic' }).Count
        PendingReboot  = (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending')
    }

    Write-Host "  主机名：$($healthReport.ComputerName)"
    Write-Host "  操作系统：$($healthReport.OSVersion)"
    Write-Host "  CPU 负载：$($healthReport.CPULoad)"
    Write-Host "  内存使用：$($healthReport.MemoryUsedPct) ($($healthReport.MemoryFreeGB) GB 可用)"
    Write-Host "  已停止的自动启动服务：$($healthReport.ServicesFailed)"

    if ($healthReport.PendingReboot) {
        Write-Host "  待重启：是" -ForegroundColor Red
    } else {
        Write-Host "  待重启：否" -ForegroundColor Green
    }

    # 生成 HTML 报告
    $htmlBody = @"
<h1>新年系统健康检查报告</h1>
<p>生成时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
<h2>系统概况</h2>
<table border="1" cellpadding="5" style="border-collapse:collapse">
<tr><td>主机名</td><td>$($healthReport.ComputerName)</td></tr>
<tr><td>操作系统</td><td>$($healthReport.OSVersion)</td></tr>
<tr><td>CPU 负载</td><td>$($healthReport.CPULoad)</td></tr>
<tr><td>内存使用率</td><td>$($healthReport.MemoryUsedPct)</td></tr>
<tr><td>待重启</td><td>$($healthReport.PendingReboot)</td></tr>
</table>
"@

    $htmlBody | Out-File $ReportPath -Encoding UTF8
    Write-Host "`nHTML 报告已保存至：$ReportPath" -ForegroundColor Green
    Write-Host "`n来年自动化准备检查完毕！" -ForegroundColor Green
}

# 执行来年准备检查
Invoke-NewYearPreparation -CertificateWarningDays 60
```

执行结果示例：

```
=== 来年自动化准备检查 ===

[1/3] 检查计划任务...
  总计：24 个自定义任务
  就绪：18 | 运行中：2 | 已禁用：4

  上次执行失败的任务：
    - DailyBackup (错误码: 0x1)
    - LogRotation (错误码: 0x2)

[2/3] 检查证书到期情况...
Subject                  Thumbprint       Expires    DaysLeft Status
-------                  ----------       -------    -------- ------
CN=web.vichamp.com       3A2F8B1C9D0E4... 2026-01-15       22 紧急
CN=api.internal.local    7E6D5C4B3A2F1... 2026-02-20       58 警告

[3/3] 系统健康检查...
  主机名：SRV-PROD-01
  操作系统：Microsoft Windows Server 2022 Standard
  CPU 负载：23%
  内存使用：67.5% (7.26 GB 可用)
  已停止的自动启动服务：2
  待重启：是

HTML 报告已保存至：C:\Users\admin\Desktop\NewYear-HealthCheck-20251224.html

来年自动化准备检查完毕！
```

## 注意事项

1. **权限要求**：事件日志查询和计划任务管理需要管理员权限，建议以提升模式运行 PowerShell，或在脚本开头添加 `#Requires -RunAsAdministrator` 确保权限充足。
2. **大日志处理**：`Get-WinEvent` 在处理整年事件日志时可能消耗大量内存。对于事件量超过十万条的日志源，建议按月份分批查询后合并统计，避免内存溢出。
3. **归档前验证**：执行日志清理前务必先用 `-WhatIf` 参数预览操作范围，确认无误后再正式执行。已压缩的归档文件应存放到独立存储或异地备份，避免与原始数据在同一磁盘上。
4. **证书到期监控**：建议将证书到期检查集成到日常监控流程中（如每周执行一次），而非仅在年底检查。可以在脚本中加入邮件通知逻辑，在证书到期前 30 天和 7 天分别发送提醒。
5. **跨平台兼容**：本文部分示例使用了 Windows 特有的模块（如 `ScheduledTask`、`Cert:` 驱动器）。如果在 Linux 或 macOS 上运行 PowerShell 7，需要使用对应的平台命令替代，如 `crontab -l` 替代计划任务检查。
6. **报告持续化**：年度报告建议统一存放并纳入版本管理。可以配合 Git 仓库或 SharePoint 文档库，每年追加新报告，形成连续的运维历史档案，便于长期趋势分析和审计回溯。
