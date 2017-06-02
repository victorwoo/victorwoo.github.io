---
layout: post
title: "PowerShell 技能连载 - 查找两个日期之间的所有日子"
date: 2014-07-07 00:00:00
description: PowerTip of the Day - Finding Dates Between Two Dates
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
如果您需要知道两个日期之间的间隔天数，那么可以用 `New-TimeSpan` 轻松地获得：

    $startdate = Get-Date
    $enddate = Get-Date -Date '2014-09-12'
    
    $difference = New-TimeSpan -Start $startdate -End $enddate
    $difference.Days

然而，如果您不仅想知道两者之间的间隔天数，而且还希望精确地获取每一天的日期对象，那么可以用这个方法：

    $startdate = Get-Date
    $enddate = Get-Date -Date '2014-09-12'
    
    $difference = New-TimeSpan -Start $startdate -End $enddate
    $days = [Math]::Ceiling($difference.TotalDays)+1
    
    1..$days | ForEach-Object {
      $startdate
      $startdate = $startdate.AddDays(1)
    }
    
这一次，PowerShell 输出两个指定日期之间的所有日期对象。

当您了解了精确获取每个日期对象（而不仅是总天数）的方法之后，您可以过滤（例如以星期数），并查找距离您放假或退休之前还有多少个星期天或工作日。

以下代码是获取工作日用的：

    $startdate = Get-Date
    $enddate = Get-Date -Date '2014-09-12'
    
    $difference = New-TimeSpan -Start $startdate -End $enddate
    $difference.Days
    
    $days = [Math]::Ceiling($difference.TotalDays)+1
    
    1..$days | ForEach-Object {
      $startdate
      $startdate = $startdate.AddDays(1)
    } |
      Where-Object { $_.DayOfWeek -gt 0 -and $_.DayOfWeek -lt 6}
    

这段代码时统计工作日天数用的：

    $startdate = Get-Date
    $enddate = Get-Date -Date '2014-09-12'
    
    $difference = New-TimeSpan -Start $startdate -End $enddate
    "Days in all: " + $difference.Days
    
    $days = [Math]::Ceiling($difference.TotalDays)+1
    
    $workdays = 1..$days | ForEach-Object {
      $startdate
      $startdate = $startdate.AddDays(1)
    } |
      Where-Object { $_.DayOfWeek -gt 0 -and $_.DayOfWeek -lt 6} |
      Measure-Object |
      Select-Object -ExpandProperty Count
    
    "Workdays: $workdays"

<!--more-->
本文国际来源：[Finding Dates Between Two Dates](http://community.idera.com/powershell/powertips/b/tips/posts/finding-dates-between-two-dates)
