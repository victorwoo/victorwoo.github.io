---
layout: post
date: 2018-10-16 00:00:00
title: "PowerShell 技能连载 - 持续监视脚本的运行"
description: PowerTip of the Day - Keeping Track of Script Execution
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
以下是一段演示如何在 Windows 注册表中存储私人信息的代码：

```powershell
# store settings here
$Path = "HKCU:\software\powertips\settings"

# check whether key exists
$exists = Test-Path -Path $Path
if ($exists -eq $false)
{
    # if this is first run, initialize registry key
    $null = New-Item -Path $Path -Force
}

# read existing value
$currentValue = Get-ItemProperty -Path $path
$lastRun = $currentValue.LastRun
if ($lastRun -eq $null)
{
    [PSCustomObject]@{
        FirstRun = $true
        LastRun = $null
        Interval = $null
    }
}
else
{
    $lastRunDate = Get-Date -Date $lastRun
    $today = Get-Date
    $timeSpan = $today - $lastRunDate

    [PSCustomObject]@{
        FirstRun = $true
        LastRun = $lastRunDate
        Interval = $timeSpan
    }
}

# write current date and time to registry
$date = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$null = New-ItemProperty -Path $Path -Name LastRun -PropertyType String -Value $date -Force
```

当运行这段代码时，它将返回一个对象，该对象告诉您上次运行此脚本是什么时候，以及从那以后运行了多长时间。

<!--本文国际来源：[Keeping Track of Script Execution](http://community.idera.com/powershell/powertips/b/tips/posts/keeping-track-of-script-execution)-->
