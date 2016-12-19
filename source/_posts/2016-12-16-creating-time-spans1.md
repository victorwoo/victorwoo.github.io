layout: post
date: 2016-12-15 16:00:00
title: "PowerShell 技能连载 - 创建 Time Span"
description: PowerTip of the Day - Creating Time Spans
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
您可以用 `New-TimeSpan` 来定义时间的“量”，然后对某个日期增加或减少这个量。以下是一个例子：

```powershell
$1Day = New-TimeSpan -Days 1
$today = Get-Date
$yesterday = $today - $1Day

$yesterday
```

更简单的办法是使用 `DateTime` 对象的内置方法：

```powershell
$today = Get-Date
$yesterday = $today.AddDays(-1)

$yesterday
```

您也可以使用 `TimeSpan` .NET 类来创建 time span 对象：

```
PS C:\> [Timespan]::FromDays(1)

​    
Days              : 1
Hours             : 0
Minutes           : 0
Seconds           : 0
Milliseconds      : 0
Ticks             : 864000000000
TotalDays         : 1
TotalHours        : 24
TotalMinutes      : 1440
TotalSeconds      : 86400
TotalMilliseconds : 86400000
```
<!--more-->
本文国际来源：[Creating Time Spans](http://community.idera.com/powershell/powertips/b/tips/posts/creating-time-spans1)
