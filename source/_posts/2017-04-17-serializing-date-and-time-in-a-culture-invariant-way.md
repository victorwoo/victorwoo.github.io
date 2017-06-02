---
layout: post
date: 2017-04-17 00:00:00
title: "PowerShell 技能连载 - 用区域性固定的方式序列化日期和时间"
description: PowerTip of the Day - Serializing Date and Time in a Culture-Invariant Way
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
当您保存日期和时间到文本中时，例如导出到 CSV 时，或创建文本报告时，`DateTime` 对象将会按照您的区域设置转换为相应的日期和时间格式：

```powershell
PS> $date = Get-Date -Date '2017-02-03 19:22:11'

PS> "$date"
02/03/2017 19:22:11

PS> $date.ToString()
03.02.2017 19:22:11

PS> Get-Date -Date $date -DisplayHint DateTime

Freitag, 3. Februar 2017 19:22:11
```

这些都是和区域有关的格式，所以当其他人打开您的数据，将它转换为真实的日期时间可能会失败。这就是为什么推荐将日期时间信息保存为文本时将它转换为区域无关的 ISO 格式：

```powershell
    PS> Get-Date -Date $date -Format 'yyyy-MM-dd HH:mm:ss'
    2017-02-03 19:22:11

    PS>
```

该 ISO 格式重视能正确地转回 `DateTime` 对象，无论您的机器用的是什么语言：

```powershell
PS> [DateTime]'2017-02-03 19:22:11'

Friday, February 3, 2017 19:22:11
```

另外，这种设计保证它们在使用字母排序时顺序是正确的。

<!--more-->
本文国际来源：[Serializing Date and Time in a Culture-Invariant Way](http://community.idera.com/powershell/powertips/b/tips/posts/serializing-date-and-time-in-a-culture-invariant-way)
