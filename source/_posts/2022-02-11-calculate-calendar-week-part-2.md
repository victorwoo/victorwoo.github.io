---
layout: post
date: 2022-02-11 00:00:00
title: "PowerShell 技能连载 - 计算第几周（第 2 部分）"
description: PowerTip of the Day - Calculate Calendar Week (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技能中，我们解释了如何计算给定日期的日历周。如您所见，这取决于文化和日历设置，并且可能因文化而异。

这就是为什么还有 "ISOWeek" 的原因：它遵守 ISO 8601 并且是标准化的。不幸的是，.NET 中的经典 API 并不总是能计算出正确的 ISOWeek。

这就是为什么微软在 .NET Standard（PowerShell 7 使用的可移植 .NET）和 .NET Framework 5 中添加了一个名为 "ISOWeek" 的全新类。

下面这行代码返回任何日期的 ISOWeek（当在 PowerShell 7 中运行时）：

```powershell
PS> [System.Globalization.ISOWeek]::GetWeekOfYear('2022-01-01')
52
```

在 Windows PowerShell 中运行时，同样的代码会返回红色的异常，因为 Windows PowerShell 基于完整的 .NET Framework，而在当前版本中尚不支持此 API。

<!--本文国际来源：[Calculate Calendar Week (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/calculate-calendar-week-part-2)-->

