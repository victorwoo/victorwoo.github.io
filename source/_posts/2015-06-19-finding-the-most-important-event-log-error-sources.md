layout: post
date: 2015-06-19 11:00:00
title: "PowerShell 技能连载 - 查找最重要的错误系统日志"
description: PowerTip of the Day - Finding the Most Important Event Log Error Sources
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
如果您没有充裕的时间来调查您系统日志中出现频率最高的错误来源，请试试这行代码：

    Get-EventLog -LogName System -EntryType Error, Warning |
     Group-Object -Property Source |
     Sort-Object -Property Count -Descending

当您找到导致一系列错误（或警告）的源头时，这行代码可以显示错误的细节：

    # change this variable to the name of the source you want
    # to explore:
    $source = 'Schannel'
    Get-EventLog -LogName System -Source $source |
      Out-GridView

<!--more-->
本文国际来源：[Finding the Most Important Event Log Error Sources](http://powershell.com/cs/blogs/tips/archive/2015/06/19/finding-the-most-important-event-log-error-sources.aspx)
