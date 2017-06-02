---
layout: post
date: 2017-04-14 00:00:00
title: "PowerShell 技能连载 - 将时钟周期转换为日期和时间（第二部分）"
description: PowerTip of the Day - Converting Ticks to Date and Time (Part 2)
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
在前一个技能中我们解释了如何将用时钟周期数表达的日期时间转换为真实的 `DateTime` 格式。然而，现实中有两种不同的时钟周期格式，以下是如何转换数字型日期时间信息的概述：

```powershell
PS> $date = Get-Date -Date '2017-02-03 19:22:11'
PS> $ticks = $date.Ticks
PS> $ticks
636217465310000000

PS> [DateTime]$ticks
Friday, February 3, 2017 19:22:11

PS> [DateTime]::FromBinary($ticks)
Friday, February 3, 2017 19:22:11

PS> [DateTime]::FromFileTime($ticks)
Friday, February 3, 3617 20:22:11

PS> [DateTime]::FromFileTimeUtc($ticks)
Friday, February 3, 3617 19:22:11
```

如您所见，将时钟周期转换为 `DateTime` 和执行 `FromBinary()` 静态方法的效果是一样的。但是 `FromeFileTime()` 做了什么？它似乎把你发送到了遥远的将来。

这个例子显示了到底发生了什么：

```powershell
PS> $date1 = [DateTime]::FromBinary($ticks)
PS> $date2 = [DateTime]::FromFileTime($ticks)
PS> $date2 - $date1

Days              : 584388
Hours             : 1
Minutes           : 0
Seconds           : 0
Milliseconds      : 0
Ticks             : 504911268000000000
TotalDays         : 584388,041666667
TotalHours        : 14025313
TotalMinutes      : 841518780
TotalSeconds      : 50491126800
TotalMilliseconds : 50491126800000

PS> ($date2 - $date1).Days / 365.25
1599,96714579055
```

`FromeFileTime()` 只是增加了 1601 年（因为闰年，实际计算结果略有出入）。Windows 的某些部分（例如 Active Directory）从 1601 年 1 月 1 日开始计算日期。对于这些情况，请使用 `FromeFileTime()` 来获取正确的日期时间。

<!--more-->
本文国际来源：[Converting Ticks to Date and Time (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/converting-ticks-to-date-and-time-part-2)
