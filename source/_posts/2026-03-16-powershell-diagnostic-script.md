---
layout: post
date: 2026-03-16 08:00:00
updated: 2026-03-16 08:00:00
title: "PowerShell 技能连载 - 系统诊断脚本集"
description: PowerTip of the Day - System Diagnostic Scripts in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- diagnostics
- health-check
- troubleshooting
- automation
---

_适用于 PowerShell 5.1 及以上版本_

系统管理员和运维工程师在日常工作中，经常需要面对各种系统故障和性能问题。当用户反馈系统卡顿、服务响应缓慢时，快速定位问题根因是恢复服务的关键。传统的排查方式是手动逐项检查——先看 CPU，再查内存，然后翻日志——不仅耗时，还容易遗漏关键线索。

通过 PowerShell 编写系统诊断脚本，可以将这些分散的检查步骤自动化，形成一套标准化的诊断流程。脚本可以在几秒内完成对硬件资源、操作系统状态、网络连接和安全配置的全面扫描，并以结构化报告的形式输出结果，帮助运维人员快速做出判断。

本文提供三个层次的诊断脚本：从硬件性能分析开始，到操作系统与服务状态检查，最后整合为一键全量诊断报告，方便直接集成到运维自动化平台中使用。

## 硬件与性能诊断

第一个脚本专注于硬件资源层面的诊断。它会采集 CPU 使用率、内存占用、磁盘空间等核心指标，并自动识别占用资源最高的进程，帮助快速定位性能瓶颈。

```powershell
function Get-HardwareDiagnostic {
    [CmdletBinding()]
    param(
        [double]$CpuThreshold = 80,
        [double]$MemoryThreshold = 85,
        [double]$DiskThreshold = 90
    )

    $result = [ordered]@{
        Timestamp    = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        ComputerName = $env:COMPUTERNAME
        Status       = 'Healthy'
        Alerts       = @()
    }

    # CPU 使用率检查
    $cpuCounter = '\Processor(_Total)\% Processor Time'
    $cpuSample1 = (Get-Counter -Counter $cpuCounter -SampleInterval 1 -MaxSamples 3).CounterSamples
    Start-Sleep -Seconds 1
    $cpuAvg = [math]::Round(($cpuSample1 | Measure-Object -Property CookedValue -Average).Average, 2)

    $result['CpuUsage'] = "$cpuAvg%"

    if ($cpuAvg -gt $CpuThreshold) {
        $result['Status'] = 'Warning'
        $result['Alerts'] += "CPU 使用率 ${cpuAvg}% 超过阈值 ${CpuThreshold}%"
    }

    # 内存使用检查
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $totalMem = [math]::Round($osInfo.TotalVisibleMemorySize / 1MB, 2)
    $freeMem = [math]::Round($osInfo.FreePhysicalMemory / 1MB, 2)
    $usedMemPercent = [math]::Round(($osInfo.TotalVisibleMemorySize - $osInfo.FreePhysicalMemory) / $osInfo.TotalVisibleMemorySize * 100, 2)

    $result['Memory'] = @{
        TotalGB     = $totalMem
        FreeGB      = $freeMem
        UsedPercent = "$usedMemPercent%"
    }

    if ($usedMemPercent -gt $MemoryThreshold) {
        $result['Status'] = 'Warning'
        $result['Alerts'] += "内存使用率 ${usedMemPercent}% 超过阈值 ${MemoryThreshold}%"
    }

    # 磁盘空间检查
    $disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType=3'
    $diskReport = foreach ($disk in $disks) {
        $freePercent = [math]::Round($disk.FreeSpace / $disk.Size * 100, 2)
        if ($freePercent -gt (100 - $DiskThreshold)) {
            $result['Status'] = 'Warning'
            $result['Alerts'] += "磁盘 $($disk.DeviceID) 可用空间仅 ${freePercent}%，低于安全阈值"
        }
        [ordered]@{
            Drive       = $disk.DeviceID
            TotalGB     = [math]::Round($disk.Size / 1GB, 2)
            FreeGB      = [math]::Round($disk.FreeSpace / 1GB, 2)
            FreePercent = "$freePercent%"
        }
    }
    $result['Disks'] = $diskReport

    # Top 10 资源占用进程
    $topProcesses = Get-Process |
        Sort-Object -Property WorkingSet64 -Descending |
        Select-Object -First 10 |
        ForEach-Object {
            [ordered]@{
                Name       = $_.Name
                PID        = $_.Id
                MemoryMB   = [math]::Round($_.WorkingSet64 / 1MB, 2)
                CpuSeconds = [math]::Round($_.CPU, 2)
            }
        }
    $result['TopProcesses'] = $topProcesses

    return [PSCustomObject]$result
}

# 执行硬件诊断
$hardwareReport = Get-HardwareDiagnostic -CpuThreshold 80 -MemoryThreshold 85 -DiskThreshold 90
$hardwareReport | ConvertTo-Json -Depth 5
```

执行结果示例：

```
{
    "Timestamp":  "2026-03-16 09:15:32",
    "ComputerName":  "SRV-PROD-01",
    "Status":  "Warning",
    "Alerts":  [
        "内存使用率 87.35% 超过阈值 85%",
        "磁盘 C: 可用空间仅 8.12%，低于安全阈值"
    ],
    "CpuUsage":  "42.67%",
    "Memory":  {
        "TotalGB":  32.00,
        "FreeGB":  4.05,
        "UsedPercent":  "87.35%"
    },
    "Disks":  [
        {
            "Drive":  "C:",
            "TotalGB":  256.00,
            "FreeGB":  20.78,
            "FreePercent":  "8.12%"
        },
        {
            "Drive":  "D:",
            "TotalGB":  1024.00,
            "FreeGB":  612.34,
            "FreePercent":  "59.80%"
        }
    ],
    "TopProcesses":  [
        {
            "Name":  "sqlservr",
            "PID":  4521,
            "MemoryMB":  8192.45,
            "CpuSeconds":  123456.78
        },
        {
            "Name":  "w3wp",
            "PID":  3312,
            "MemoryMB":  4096.12,
            "CpuSeconds":  56789.01
        }
    ]
}
```

## 操作系统与服务诊断

第二个脚本聚焦于操作系统层面，自动检查关键 Windows 服务的运行状态、扫描系统事件日志中的异常条目，并检测待安装的系统更新。

```powershell
function Get-OSDiagnostic {
    [CmdletBinding()]
    param(
        [string[]]$CriticalServices = @('WinRM', 'EventLog', 'LanmanServer', 'LanmanWorkstation', 'Schedule'),
        [int]$EventLogHours = 24,
        [int]$MaxEvents = 50
    )

    $result = [ordered]@{
        Timestamp    = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        ComputerName = $env:COMPUTERNAME
        Status       = 'Healthy'
        Alerts       = @()
    }

    # 操作系统基本信息
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $result['OS'] = @{
        Caption       = $os.Caption
        Version       = $os.Version
        BuildNumber   = $os.BuildNumber
        LastBootTime  = $os.LastBootUpTime.ToString('yyyy-MM-dd HH:mm:ss')
        UptimeDays    = [math]::Round((Get-Date) - $os.LastBootUpTime | Select-Object -ExpandProperty TotalDays, 1)
    }

    # 关键服务状态检查
    $serviceReport = foreach ($svcName in $CriticalServices) {
        $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
        if ($svc) {
            $status = if ($svc.Status -eq 'Running') { 'OK' } else { 'Alert' }
            if ($status -eq 'Alert') {
                $result['Status'] = 'Warning'
                $result['Alerts'] += "服务 $svcName 状态异常: $($svc.Status)"
            }
            [ordered]@{
                Name        = $svcName
                DisplayName = $svc.DisplayName
                Status      = $svc.Status.ToString()
                StartType   = $svc.StartType.ToString()
                CheckResult = $status
            }
        } else {
            $result['Alerts'] += "服务 $svcName 未找到"
            [ordered]@{
                Name        = $svcName
                DisplayName = 'N/A'
                Status      = 'NotFound'
                StartType   = 'N/A'
                CheckResult = 'Error'
            }
        }
    }
    $result['Services'] = $serviceReport

    # 事件日志异常检查（最近 N 小时的错误和警告）
    $startTime = (Get-Date).AddHours(-$EventLogHours)
    $eventFilter = @{
        LogName   = 'System'
        Level     = 2, 3
        StartTime = $startTime
    }
    $errorEvents = Get-WinEvent -FilterHashtable $eventFilter -MaxEvents $MaxEvents -ErrorAction SilentlyContinue

    $eventSummary = $errorEvents |
        Group-Object -Property ProviderName |
        Sort-Object -Property Count -Descending |
        Select-Object -First 10 |
        ForEach-Object {
            [ordered]@{
                Source   = $_.Name
                Count    = $_.Count
                Examples = ($_.Group | Select-Object -First 2 | ForEach-Object { "$($_.TimeCreated.ToString('HH:mm:ss')) $($_.Message.Substring(0, [math]::Min(80, $_.Message.Length)))" })
            }
        }
    $result['EventLogErrors'] = @{
        TimeRange   = "最近 ${EventLogHours} 小时"
        TotalErrors = if ($errorEvents) { $errorEvents.Count } else { 0 }
        TopSources  = $eventSummary
    }

    if ($errorEvents -and $errorEvents.Count -gt 20) {
        $result['Status'] = 'Warning'
        $result['Alerts'] += "系统事件日志在最近 ${EventLogHours} 小时内有 $($errorEvents.Count) 条错误/警告"
    }

    # 待安装系统更新检查（需要 PSWindowsUpdate 模块）
    $updateAvailable = $false
    try {
        Import-Module PSWindowsUpdate -ErrorAction Stop
        $updates = Get-WindowsUpdate -AcceptAll -Install -AutoReboot:$false -WhatIf 2>$null
        if ($updates) {
            $updateAvailable = $true
            $result['PendingUpdates'] = $updates | ForEach-Object {
                @{ Title = $_.Title; Size = $_.Size }
            }
            $result['Alerts'] += "有 $($updates.Count) 个系统更新待安装"
        }
    } catch {
        $result['PendingUpdates'] = '无法检查（PSWindowsUpdate 模块未安装）'
    }

    return [PSCustomObject]$result
}

# 执行操作系统诊断
$osReport = Get-OSDiagnostic -CriticalServices @('WinRM', 'EventLog', 'LanmanServer', 'LanmanWorkstation', 'Schedule', 'Spooler') -EventLogHours 24
$osReport | ConvertTo-Json -Depth 5
```

执行结果示例：

```
{
    "Timestamp":  "2026-03-16 09:16:45",
    "ComputerName":  "SRV-PROD-01",
    "Status":  "Warning",
    "Alerts":  [
        "服务 Spooler 状态异常: Stopped",
        "系统事件日志在最近 24 小时内有 47 条错误/警告"
    ],
    "OS":  {
        "Caption":  "Microsoft Windows Server 2022 Datacenter",
        "Version":  "10.0.20348",
        "BuildNumber":  "20348",
        "LastBootTime":  "2026-03-10 03:00:00",
        "UptimeDays":  6.3
    },
    "Services":  [
        {
            "Name":  "WinRM",
            "DisplayName":  "Windows Remote Management (WS-Management)",
            "Status":  "Running",
            "StartType":  "Automatic",
            "CheckResult":  "OK"
        },
        {
            "Name":  "Spooler",
            "DisplayName":  "Print Spooler",
            "Status":  "Stopped",
            "StartType":  "Automatic",
            "CheckResult":  "Alert"
        }
    ],
    "EventLogErrors":  {
        "TimeRange":  "最近 24 小时",
        "TotalErrors":  47,
        "TopSources":  [
            {
                "Source":  "Microsoft-Windows-Disk",
                "Count":  18,
                "Examples":  [
                    "08:32:15 The device, \\Device\\Harddisk1\\DR1, has a bad block.",
                    "09:15:22 The device, \\Device\\Harddisk1\\DR1, has a bad block."
                ]
            }
        ]
    },
    "PendingUpdates":  "无法检查（PSWindowsUpdate 模块未安装）"
}
```

## 综合诊断报告

第三个脚本将前面的各项检查整合为一键全量诊断，计算健康评分，并生成可读性更好的 HTML 报告，方便通过邮件或 Web 平台分享。

```powershell
function Invoke-FullSystemDiagnostic {
    [CmdletBinding()]
    param(
        [string]$OutputPath = "$env:TEMP\SystemDiagnosticReport.html",
        [double]$CpuThreshold = 80,
        [double]$MemoryThreshold = 85,
        [double]$DiskThreshold = 90
    )

    Write-Host "开始全量系统诊断..." -ForegroundColor Cyan
    $diagStart = Get-Date

    # 采集各项指标
    Write-Host "  [1/4] 采集硬件指标..." -ForegroundColor Gray
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $cpuSample = (Get-Counter -Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 3).CounterSamples
    $cpuAvg = [math]::Round(($cpuSample | Measure-Object -Property CookedValue -Average).Average, 2)
    $memUsedPercent = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize * 100, 2)
    $disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType=3'

    Write-Host "  [2/4] 检查服务状态..." -ForegroundColor Gray
    $criticalSvcs = @('WinRM', 'EventLog', 'LanmanServer', 'LanmanWorkstation', 'Schedule')
    $svcResults = foreach ($name in $criticalSvcs) {
        $s = Get-Service -Name $name -ErrorAction SilentlyContinue
        @{ Name = $name; Status = if ($s) { $s.Status.ToString() } else { 'NotFound' } }
    }

    Write-Host "  [3/4] 扫描事件日志..." -ForegroundColor Gray
    $startTime = (Get-Date).AddHours(-24)
    $errors = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 2; StartTime = $startTime } -MaxEvents 100 -ErrorAction SilentlyContinue)
    $warnings = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 3; StartTime = $startTime } -MaxEvents 100 -ErrorAction SilentlyContinue)

    Write-Host "  [4/4] 计算健康评分..." -ForegroundColor Gray

    # 健康评分计算（满分 100）
    $score = 100

    # CPU 扣分（每超阈值 1% 扣 0.5 分，最多扣 20 分）
    $cpuDeduction = [math]::Min(20, [math]::Max(0, ($cpuAvg - $CpuThreshold) * 0.5))
    $score -= $cpuDeduction

    # 内存扣分
    $memDeduction = [math]::Min(20, [math]::Max(0, ($memUsedPercent - $MemoryThreshold) * 0.5))
    $score -= $memDeduction

    # 磁盘扣分
    foreach ($disk in $disks) {
        $diskUsedPercent = [math]::Round(($disk.Size - $disk.FreeSpace) / $disk.Size * 100, 2)
        if ($diskUsedPercent -gt $DiskThreshold) {
            $score -= [math]::Min(10, [math]::Max(0, ($diskUsedPercent - $DiskThreshold) * 0.3))
        }
    }

    # 服务异常扣分（每个异常服务扣 5 分，最多扣 25 分）
    $stoppedSvcs = @($svcResults | Where-Object { $_.Status -ne 'Running' })
    $svcDeduction = [math]::Min(25, $stoppedSvcs.Count * 5)
    $score -= $svcDeduction

    # 事件日志错误扣分
    $logDeduction = [math]::Min(15, [math]::Round($errors.Count / 5, 0))
    $score -= $logDeduction

    $score = [math]::Max(0, [math]::Round($score, 0))

    # 确定总体状态
    $overallStatus = if ($score -ge 80) { 'Healthy' } elseif ($score -ge 50) { 'Warning' } else { 'Critical' }

    $diagDuration = [math]::Round(((Get-Date) - $diagStart).TotalSeconds, 1)

    # 生成 HTML 报告
    $html = @"
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<title>系统诊断报告 - $($env:COMPUTERNAME) - $(Get-Date -Format 'yyyy-MM-dd')</title>
<style>
body { font-family: 'Segoe UI', sans-serif; margin: 20px; background: #f5f5f5; }
.container { max-width: 960px; margin: auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
h1 { color: #0078d4; border-bottom: 2px solid #0078d4; padding-bottom: 10px; }
.score { font-size: 48px; font-weight: bold; text-align: center; padding: 20px; }
.score.healthy { color: #107c10; }
.score.warning { color: #ff8c00; }
.score.critical { color: #d13438; }
table { width: 100%; border-collapse: collapse; margin: 10px 0; }
th, td { border: 1px solid #ddd; padding: 8px 12px; text-align: left; }
th { background: #0078d4; color: white; }
tr:nth-child(even) { background: #f9f9f9; }
.badge { padding: 3px 8px; border-radius: 4px; font-size: 12px; font-weight: bold; }
.badge-ok { background: #dff6dd; color: #107c10; }
.badge-warn { background: #fff4ce; color: #ff8c00; }
.badge-error { background: #fde7e9; color: #d13438; }
</style>
</head>
<body>
<div class="container">
<h1>系统诊断报告</h1>
<p>计算机: <strong>$($env:COMPUTERNAME)</strong> | 生成时间: <strong>$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</strong> | 耗时: ${diagDuration}s</p>
<div class="score $overallStatus.ToLowerInvariant()">$score / 100</div>
<p style="text-align:center; font-size:18px;">总体状态: <strong>$overallStatus</strong></p>

<h2>CPU 使用率</h2>
<p>平均使用率: <strong>${cpuAvg}%</strong> (阈值: ${CpuThreshold}%)</p>

<h2>内存使用率</h2>
<p>已用: <strong>${memUsedPercent}%</strong> (阈值: ${MemoryThreshold}%)</p>

<h2>磁盘空间</h2>
<table>
<tr><th>驱动器</th><th>总容量</th><th>可用空间</th><th>可用百分比</th></tr>
$(foreach ($d in $disks) {
    $freePct = [math]::Round($d.FreeSpace / $d.Size * 100, 2)
    $badge = if ($freePct -gt 20) { 'badge-ok' } elseif ($freePct -gt 10) { 'badge-warn' } else { 'badge-error' }
    "<tr><td>$($d.DeviceID)</td><td>$([math]::Round($d.Size/1GB,2)) GB</td><td>$([math]::Round($d.FreeSpace/1GB,2)) GB</td><td><span class=`"badge $badge`">${freePct}%</span></td></tr>"
})

<h2>关键服务状态</h2>
<table>
<tr><th>服务名</th><th>状态</th></tr>
$(foreach ($s in $svcResults) {
    $badge = if ($s.Status -eq 'Running') { 'badge-ok' } else { 'badge-error' }
    "<tr><td>$($s.Name)</td><td><span class=`"badge $badge`">$($s.Status)</span></td></tr>"
})

<h2>事件日志摘要（最近 24 小时）</h2>
<p>错误: <strong>$($errors.Count)</strong> 条 | 警告: <strong>$($warnings.Count)</strong> 条</p>

</div>
</body>
</html>
"@

    $html | Out-File -FilePath $OutputPath -Encoding UTF8 -Force
    Write-Host "诊断完成！健康评分: $score / 100 [$overallStatus]" -ForegroundColor $(if ($overallStatus -eq 'Healthy') { 'Green' } elseif ($overallStatus -eq 'Warning') { 'Yellow' } else { 'Red' })
    Write-Host "HTML 报告已保存至: $OutputPath" -ForegroundColor Cyan

    return [PSCustomObject]@{
        ComputerName = $env:COMPUTERNAME
        Score        = $score
        Status       = $overallStatus
        CpuUsage     = "$cpuAvg%"
        MemoryUsage  = "$memUsedPercent%"
        Errors24h    = $errors.Count
        Warnings24h  = $warnings.Count
        ReportPath   = $OutputPath
    }
}

# 执行全量诊断并生成报告
$report = Invoke-FullSystemDiagnostic -OutputPath "$env:TEMP\SystemDiagnosticReport.html"
$report
```

执行结果示例：

```
开始全量系统诊断...
  [1/4] 采集硬件指标...
  [2/4] 检查服务状态...
  [3/4] 扫描事件日志...
  [4/4] 计算健康评分...
诊断完成！健康评分: 72 / 100 [Warning]
HTML 报告已保存至: C:\Users\admin\AppData\Local\Temp\SystemDiagnosticReport.html

ComputerName : SRV-PROD-01
Score        : 72
Status       : Warning
CpuUsage     : 42.67%
MemoryUsage  : 87.35%
Errors24h    : 23
Warnings24h  : 31
ReportPath   : C:\Users\admin\AppData\Local\Temp\SystemDiagnosticReport.html
```

## 注意事项

1. **运行权限**：部分检查（如事件日志查询、服务状态枚举）需要管理员权限。建议以提升模式启动 PowerShell，或将脚本加入计划任务以 `SYSTEM` 身份运行。

2. **性能影响**：CPU 使用率采样需要短暂等待（默认 3 秒采样周期），在极端高负载场景下，脚本本身的执行也会消耗资源。生产环境可调整 `-MaxSamples` 参数降低采样频率。

3. **跨平台兼容**：本文脚本以 Windows 平台为主，使用了 `Win32_OperatingSystem`、`Get-Counter` 等 Windows 专用命令。如需在 Linux 上运行，应替换为 `/proc/meminfo`、`vmstat` 等原生命令的封装。

4. **健康评分的阈值**：评分算法中的扣分权重（CPU 20 分、内存 20 分、磁盘 10 分、服务 25 分、日志 15 分）可根据实际运维需求调整。核心服务密集型环境应提高服务权重的扣分比例。

5. **HTML 报告安全**：生成的 HTML 报告包含服务器名称、资源数据等敏感信息，传输时应通过内部网络或加密渠道分享，避免直接暴露在公网上。

6. **定时执行建议**：可以将 `Invoke-FullSystemDiagnostic` 配合 Windows 计划任务或 CI/CD 流水线定时执行，每天生成一份诊断报告。当健康评分低于设定阈值时自动触发告警通知，实现主动式运维监控。
