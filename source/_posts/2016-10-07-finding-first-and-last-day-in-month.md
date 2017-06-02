---
layout: post
date: 2016-10-07 00:00:00
title: "PowerShell 技能连载 - 查找一个月中的第一天和最后一天"
description: PowerTip of the Day - Finding First and Last Day in Month
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
您是否曾需要了解某个月的第一天和最后一天？

以下是一个简单的实现方法：

```powershell
# specify the date you want to examine
# default is today
$date = Get-Date
$year = $date.Year
$month = $date.Month

# create a new DateTime object set to the first day of a given month and year
$startOfMonth = Get-Date -Year $year -Month $month -Day 1 -Hour 0 -Minute 0 -Second 0 -Millisecond 0
# add a month and subtract the smallest possible time unit
$endOfMonth = ($startOfMonth).AddMonths(1).AddTicks(-1)

$startOfMonth
$endOfMonth
```

<!--more-->
本文国际来源：[Finding First and Last Day in Month](http://community.idera.com/powershell/powertips/b/tips/posts/finding-first-and-last-day-in-month)
