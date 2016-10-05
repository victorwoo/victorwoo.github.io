layout: post
title: "PowerShell 技能连载 - 查找昨天以来的错误"
date: 2014-03-12 00:00:00
description: PowerTip of the Day - Finding Errors since Yesterday
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
要获取一个时间段内的数据，相对日期的作用十分重要，它能避免硬编码日期和时间值。

这段代码将会从系统日志中获取昨天起（24 小时以内）的所有错误和警告事件：

    $today = Get-Date
    $1day = New-TimeSpan -Days 1
    
    $yesterday = $today - $1day
    
    Get-EventLog -LogName system -EntryType Error, Warning -After $yesterday 

<!--more-->
本文国际来源：[Finding Errors since Yesterday](http://community.idera.com/powershell/powertips/b/tips/posts/finding-errors-since-yesterday)
