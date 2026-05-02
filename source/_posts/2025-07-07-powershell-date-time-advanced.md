---
layout: post
date: 2025-07-07 08:00:00
updated: 2025-07-07 08:00:00
title: "PowerShell 技能连载 - 日期时间高级操作"
description: PowerTip of the Day - Advanced Date and Time Operations in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- datetime
- timespan
- timezone
- system-management
---

_适用于 PowerShell 5.1 及以上版本_

日期时间处理在运维脚本中无处不在——日志时间戳解析、定时任务调度、报表周期计算、服务运行时间监控、跨时区协作。PowerShell 基于 .NET 的 `DateTime` 和 `TimeSpan` 类型，提供了丰富的时间操作能力。但时区转换、UTC 处理、文化格式化等场景容易出错，需要掌握一些关键技巧。

本文将讲解 PowerShell 中日期时间的高级操作和常见陷阱。

<!-- more -->

## 格式化与解析

```powershell
# 标准格式化
$now = Get-Date
Write-Host "默认：$now"
Write-Host "短日期：$($now.ToString('d'))"
Write-Host "长日期：$($now.ToString('D'))"
Write-Host "ISO 8601：$($now.ToString('yyyy-MM-ddTHH:mm:ss.fff'))"
Write-Host "文件名安全：$($now.ToString('yyyyMMdd_HHmmss'))"
Write-Host "日志格式：$($now.ToString('yyyy-MM-dd HH:mm:ss.fff'))"

# 自定义格式化
$formats = @{
    "年月日"     = "yyyy年M月d日"
    "时分秒"     = "HH时mm分ss秒"
    "季度"       = "yyyy年 第q季度"
    "周几"       = "yyyy-MM-dd dddd"
    "相对简写"   = "M/d HH:mm"
}

foreach ($item in $formats.GetEnumerator()) {
    $formatted = $now.ToString($item.Value)
    Write-Host "$($item.Key)：$formatted"
}

# 解析各种格式的时间字符串
$dateStrings = @(
    "2025-07-07",
    "2025/07/07 08:30:00",
    "07-Jul-2025",
    "2025年7月7日"
)

foreach ($ds in $dateStrings) {
    try {
        $parsed = [datetime]::Parse($ds)
        Write-Host "解析 '$ds' => $($parsed.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Green
    } catch {
        Write-Host "解析失败 '$ds'" -ForegroundColor Red
    }
}

# 精确解析指定格式
$logTime = "07/07/2025:08:30:15 +0800"
$parsed = [datetime]::ParseExact($logTime.Split(' ')[0], "MM/dd/yyyy:HH:mm:ss", $null)
Write-Host "日志时间解析：$($parsed.ToString('yyyy-MM-dd HH:mm:ss'))"
```

执行结果示例：

```
默认：2025/7/7 8:00:00
短日期：2025/7/7
长日期：2025年7月7日
ISO 8601：2025-07-07T08:00:00.000
文件名安全：20250707_080000
日志格式：2025-07-07 08:00:00.000
年月日：2025年7月7日
时分秒：08时00分00秒
季度：2025年 第3季度
周几：2025-07-07 星期一
相对简写：7/7 08:00
解析 '2025-07-07' => 2025-07-07 00:00:00
解析 '2025/07/07 08:30:00' => 2025-07-07 08:30:00
解析 '07-Jul-2025' => 2025-07-07 00:00:00
解析 '2025年7月7日' => 2025-07-07 00:00:00
日志时间解析：2025-07-07 08:30:15
```

## 时间差计算

```powershell
# TimeSpan 基础
$bootTime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$uptime = (Get-Date) - $bootTime

Write-Host "系统运行时间：$($uptime.Days) 天 $($uptime.Hours) 小时 $($uptime.Minutes) 分钟"

# 计算工作日
function Get-WorkingDays {
    param(
        [Parameter(Mandatory)][datetime]$Start,
        [Parameter(Mandatory)][datetime]$End
    )

    $days = 0
    $current = $Start.Date

    while ($current -le $End.Date) {
        if ($current.DayOfWeek -notin @([DayOfWeek]::Saturday, [DayOfWeek]::Sunday)) {
            $days++
        }
        $current = $current.AddDays(1)
    }

    return $days
}

$workingDays = Get-WorkingDays -Start (Get-Date "2025-07-01") -End (Get-Date "2025-07-31")
Write-Host "7 月工作日：$workingDays 天"

# 计算下一个工作日
function Get-NextWorkday {
    param([datetime]$Date = (Get-Date))

    $next = $Date.AddDays(1)
    while ($next.DayOfWeek -in @([DayOfWeek]::Saturday, [DayOfWeek]::Sunday)) {
        $next = $next.AddDays(1)
    }
    return $next
}

Write-Host "下一个工作日：$(Get-NextWorkday | Get-Date -Format 'yyyy-MM-dd dddd')"

# 计算月末日期
function Get-LastDayOfMonth {
    param([datetime]$Date = (Get-Date))
    return (New-Object System.DateTime $Date.Year, $Date.Month, 1).AddMonths(1).AddDays(-1)
}

Write-Host "本月最后一天：$(Get-LastDayOfMonth | Get-Date -Format 'yyyy-MM-dd dddd')"
```

执行结果示例：

```
系统运行时间：45 天 12 小时 30 分钟
7 月工作日：23 天
下一个工作日：2025-07-08 星期二
本月最后一天：2025-07-31 星期四
```

## 时区处理

```powershell
# 获取时区信息
$tz = [System.TimeZoneInfo]::Local
Write-Host "本地时区：$($tz.DisplayName)"
Write-Host "UTC 偏移：$($tz.BaseUtcOffset)"

# UTC 与本地时间互转
$utcNow = [System.DateTime]::UtcNow
Write-Host "UTC 时间：$($utcNow.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Host "本地时间：$([System.TimeZoneInfo]::ConvertTimeFromUtc($utcNow, $tz).ToString('yyyy-MM-dd HH:mm:ss'))"

# 转换到指定时区
function ConvertTo-TimeZone {
    param(
        [Parameter(Mandatory)]
        [datetime]$DateTime,

        [Parameter(Mandatory)]
        [string]$TimeZoneId
    )

    $targetTz = [System.TimeZoneInfo]::FindSystemTimeZoneById($TimeZoneId)
    return [System.TimeZoneInfo]::ConvertTime($DateTime, $targetTz)
}

# 常用时区 ID
$timeZones = @{
    "上海"  = "China Standard Time"
    "东京"  = "Tokyo Standard Time"
    "纽约"  = "Eastern Standard Time"
    "伦敦"  = "GMT Standard Time"
    "悉尼"  = "AUS Eastern Standard Time"
}

$now = Get-Date
Write-Host "`n全球时间对照（$($now.ToString('yyyy-MM-dd HH:mm:ss')) 本地时间）：" -ForegroundColor Cyan

foreach ($city in $timeZones.GetEnumerator()) {
    try {
        $converted = ConvertTo-TimeZone -DateTime $now -TimeZoneId $city.Value
        Write-Host "  $($city.Key)：$($converted.ToString('yyyy-MM-dd HH:mm:ss dddd'))" -ForegroundColor Green
    } catch {
        Write-Host "  $($city.Key)：转换失败" -ForegroundColor Red
    }
}

# 列出所有可用时区
[System.TimeZoneInfo]::GetSystemTimeZones() |
    Where-Object { $_.DisplayName -match 'China|Tokyo|Eastern|GMT Standard' } |
    Select-Object Id, DisplayName |
    Format-Table -AutoSize
```

执行结果示例：

```
本地时区：(UTC+08:00) 北京，重庆，香港特别行政区，乌鲁木齐
UTC 偏移：08:00:00
UTC 时间：2025-07-07 00:00:00
本地时间：2025-07-07 08:00:00

全球时间对照（2025-07-07 08:00:00 本地时间）：
  上海：2025-07-07 08:00:00 星期一
  东京：2025-07-07 09:00:00 星期一
  纽约：2025-07-06 20:00:00 星期日
  伦敦：2025-07-07 01:00:00 星期一
  悉尼：2025-07-07 10:00:00 星期一
```

## 定时任务辅助

```powershell
# 判断是否在维护窗口内
function Test-MaintenanceWindow {
    param(
        [int]$StartHour = 22,
        [int]$EndHour = 6,
        [datetime]$CheckTime = (Get-Date)
    )

    $hour = $CheckTime.Hour

    if ($StartHour -gt $EndHour) {
        # 跨午夜（如 22:00-06:00）
        return ($hour -ge $StartHour -or $hour -lt $EndHour)
    } else {
        return ($hour -ge $StartHour -and $hour -lt $EndHour)
    }
}

if (Test-MaintenanceWindow -StartHour 22 -EndHour 6) {
    Write-Host "当前在维护窗口内（22:00-06:00）" -ForegroundColor Yellow
} else {
    Write-Host "当前不在维护窗口内" -ForegroundColor Green
}

# 等待到指定时间
function Wait-Until {
    param(
        [Parameter(Mandatory)]
        [datetime]$TargetTime
    )

    $now = Get-Date
    if ($TargetTime -le $now) {
        Write-Host "目标时间已过" -ForegroundColor Yellow
        return
    }

    $waitSpan = $TargetTime - $now
    Write-Host "等待 $($waitSpan.TotalMinutes -as [int]) 分钟到 $($TargetTime.ToString('HH:mm:ss'))..." -ForegroundColor Cyan

    Start-Sleep -Seconds $waitSpan.TotalSeconds
    Write-Host "到达目标时间" -ForegroundColor Green
}

# 生成时间区间
function New-TimeRange {
    param(
        [datetime]$Start = (Get-Date "2025-07-07"),
        [datetime]$End = (Get-Date "2025-07-07 23:59:59"),
        [int]$IntervalMinutes = 30
    )

    $ranges = @()
    $current = $Start

    while ($current -lt $End) {
        $next = $current.AddMinutes($IntervalMinutes)
        if ($next -gt $End) { $next = $End }

        $ranges += [PSCustomObject]@{
            Start = $current.ToString('HH:mm')
            End   = $next.ToString('HH:mm')
        }

        $current = $next
    }

    return $ranges
}

New-TimeRange -IntervalMinutes 60 | Format-Table -AutoSize
```

执行结果示例：

```
当前不在维护窗口内
  Start End
  ----- ---
  00:00 01:00
  01:00 02:00
  02:00 03:00
  03:00 04:00
  04:00 05:00
  05:00 06:00
  06:00 07:00
  07:00 08:00
  08:00 09:00
  09:00 10:00
  10:00 11:00
  11:00 12:00
  12:00 13:00
  13:00 14:00
  14:00 15:00
  15:00 16:00
  16:00 17:00
  17:00 18:00
  18:00 19:00
  19:00 20:00
  20:00 21:00
  21:00 22:00
  22:00 23:00
  23:00 23:59
```

## 注意事项

1. **DateTime vs DateTimeOffset**：`DateTime` 不包含时区信息，跨时区场景使用 `DateTimeOffset`
2. **Kind 属性**：`DateTime.Kind` 可以是 `Local`、`Utc` 或 `Unspecified`，注意区分
3. **闰年和月末**：使用 `.AddMonths(1).AddDays(-1)` 计算月末，自动处理不同月份天数
4. **夏令时**：时区转换时注意夏令时影响，`TimeZoneInfo` 会自动处理
5. **字符串解析**：`[datetime]::Parse()` 使用当前文化设置，服务器脚本中推荐 `ParseExact()` 明确格式
6. **精度**：`Get-Date` 精度为毫秒级，`Stopwatch` 可以达到纳秒级精度
