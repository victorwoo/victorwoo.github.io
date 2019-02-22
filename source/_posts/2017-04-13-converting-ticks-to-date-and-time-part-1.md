---
layout: post
date: 2017-04-13 00:00:00
title: "PowerShell 技能连载 - 将时钟周期转换为日期和时间（第一部分）"
description: PowerTip of the Day - Converting Ticks to Date and Time (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有时候您可能会遇到一些奇怪的日期和时间格式，它们可能用的是类似这样的 64 位 integer 数值：636264671350358729。

如果您想将这样的“时钟周期”（Windows 中最小的时间片），只需要将数字转换为 `DateTime` 类型：

```powershell
PS> [DateTime]636264671350358729

Thursday, March 30, 2017 10:38:55
```

类似地，要将一个日期转换为时钟周期，请试试这段代码：

```powershell
PS> $date = Get-Date -Date '2017-02-03 19:22:11'

PS> $date.Ticks
636217465310000000
```

比如说，您可以利用这个时钟周期来将日期和时间序列化成非特定区域的格式。

<!--本文国际来源：[Converting Ticks to Date and Time (Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/converting-ticks-to-date-and-time-part-1)-->
