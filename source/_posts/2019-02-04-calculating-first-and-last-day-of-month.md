---
layout: post
date: 2019-02-04 00:00:00
title: "PowerShell 技能连载 - 计算一个月的第一天和最后一天"
description: PowerTip of the Day - Calculating First and Last Day of Month
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
对于报表以及类似的场景，脚本可能需要获得指定月份的第一天和最后一天。第一天很简单，但最后一天依赖于月份和年份。以下是一个简单的计算器。只需要指定您需要的月份和年份：

```powershell
[ValidateRange(1,12)][int]$month = 3
$year = 2019
$last = [DateTime]::DaysInMonth($year, $month)
$first = Get-Date -Day 1 -Month $month -Year $year -Hour 0 -Minute 0 -Second 0
$last = Get-Date -Day $last -Month $month -Year $year -Hour 23 -Minute 59 -Second 59


 
PS> $first
3/1/2019 12:00:00 AM

PS> $last
3/31/2019 11:59:59 PM

PS>
```

<!--more-->
本文国际来源：[Calculating First and Last Day of Month](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/calculating-first-and-last-day-of-month)
