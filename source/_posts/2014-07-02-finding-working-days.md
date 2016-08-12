layout: post
title: "PowerShell 技能连载 - 列出工作日"
date: 2014-07-02 00:00:00
description: PowerTip of the Day - Finding Working Days
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
以下单行代码可以列出指定月份的所有工作日：

    $month = 7
    1..31 | ForEach-Object { Get-Date -Day $_ -Month $month } | 
      Where-Object { $_.DayOfWeek -gt 0 -and $_.DayOfWeek -lt 6 }
    

只需要将月份赋值给 `$month`（例子中以 7 月为例）。

多添一些代码，就可以从管道中返回工作日的数量：

    $month = 7
    1..31 | ForEach-Object { Get-Date -Day $_ -Month $month } | 
      Where-Object { $_.DayOfWeek -gt 0 -and $_.DayOfWeek -lt 6 } | 
      Measure-Object |
      Select-Object -ExpandProperty Count

<!--more-->
本文国际来源：[Finding Working Days](http://powershell.com/cs/blogs/tips/archive/2014/07/02/finding-working-days.aspx)
