---
layout: post
date: 2017-02-02 00:00:00
title: "PowerShell 技能连载 - 确定个人年龄"
description: PowerTip of the Day - Determining Person Age
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
您是如何基于生日确定一个人的年龄？您可以将 `Get-Date` 命令返回的当前时间减去生日事件，但是结果并不包含年数：

```powershell
#requires -Version 1.0

$birthday = Get-Date -Date '1978-12-09'
$today = Get-Date
$timedifference = $today - $birthday

$timedifference
```

以下是结果：

```powershell
Days              : 13905
Hours             : 16
Minutes           : 34
Seconds           : 58
Milliseconds      : 575
Ticks             : 12014516985758198
TotalDays         : 13905.6909557387
TotalHours        : 333736.582937728
TotalMinutes      : 20024194.9762637
TotalSeconds      : 1201451698.57582
TotalMilliseconds : 1201451698575.82
```

要计算年数，请取 "ticks" 的数值（衡量时间最小单位），并且转换为 datetime 类型，然后取年数并减一：

```powershell
#requires -Version 1.0
$birthdayString = '1978-12-09'
$birthday = Get-Date -Date $birthdayString
$today = Get-Date
$timedifference = $today - $birthday
$ticks = $timedifference.Ticks
$age = (New-Object DateTime -ArgumentList $ticks).Year -1
"Born on $birthdayString = $age Years old (at time of printing)"
```

这是计算结果的样子：

```powershell
Born on 1978-12-09 = 38 Years old (at time of printing)
```

<!--more-->
本文国际来源：[Determining Person Age](http://community.idera.com/powershell/powertips/b/tips/posts/determining-person-age)
