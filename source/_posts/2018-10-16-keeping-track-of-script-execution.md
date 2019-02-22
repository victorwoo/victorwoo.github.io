---
layout: post
date: 2018-10-16 00:00:00
title: "PowerShell 技能连载 - Keeping Track of Script Execution"
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
Here is a chunk of code that demonstrates how you can store private settings in the Windows Registry:

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
    

Whenever you run this code, it returns an object telling you when this script was run the last time, and how much time has passed since.

<!--本文国际来源：[Keeping Track of Script Execution](http://community.idera.com/powershell/powertips/b/tips/posts/keeping-track-of-script-execution)-->
