---
layout: post
date: 2017-10-12 00:00:00
title: "PowerShell 技能连载 - 转换奇怪的数据格式"
description: PowerTip of the Day - Converting Weird Data Formats
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有些时候，您会被奇怪的数据格式难住，例如在 log 文件中，它无法自动转换为 `DateTime` 对象。以下是一个快速的解析此类日期时间信息的方法：

```powershell
$weirdDate = '03 12 --- 1988'

[DateTime]::ParseExact($weirdDate, 'MM dd --- yyyy', $null)
```

如您所见，`ParseExact()` 用标准的 .NET 日期和时间字符，如您所愿处理自定义日期和时间格式。以下是大小写敏感的：

    yy,yyyy: Year
    M, MM, MMM, MMMM: Month
    d,dd,ddd,dddd: Day
    H, HH: Hour (24hr clock)
    h,hh: Hour (12hr clock)
    m,mm: Minute
    s,ss: Second

<!--本文国际来源：[Converting Weird Data Formats](http://community.idera.com/powershell/powertips/b/tips/posts/converting-weird-data-formats)-->
