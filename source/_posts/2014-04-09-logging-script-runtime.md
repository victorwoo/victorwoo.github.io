---
layout: post
title: "PowerShell 技能连载 - 记录脚本的运行时间"
date: 2014-04-09 00:00:00
description: PowerTip of the Day - Logging Script Runtime
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
如果您想记录脚本的运行时间，您可以使用 `Measure-Command`，但是这个 cmdlet 仅适合诊断目的，并且没有计算输出时间。

另一种方法是创建两个快照，并且在结束时计算时间差。

这段代码将告诉您 `Get-Hotfix` cmdlet 的执行时间，包括输出数据的时间：

    $start = Get-Date
    
    Get-HotFix
    
    $end = Get-Date
    Write-Host -ForegroundColor Red ('Total Runtime: ' + ($end - $start).TotalSeconds)
    
<!--more-->
本文国际来源：[Logging Script Runtime](http://community.idera.com/powershell/powertips/b/tips/posts/logging-script-runtime)
