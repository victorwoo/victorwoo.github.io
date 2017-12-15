---
layout: post
date: 2017-12-11 00:00:00
title: "PowerShell 技能连载 - 将信息转换为区域性特定的文本"
description: PowerTip of the Day - Converting Information to Culture-Specific Text
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
如果您希望将信息转换为指定的区域标准，那么可以轻松地用 `ToString()` 方法和合适的目标信息。

这个例子将短浅的日期和时间转换为法国的格式：

```powershell
$date = Get-Date
$frenchCulture = New-Object -TypeName CultureInfo("fr")
$dateString = $date.ToString($frenchCulture)
$dateString
```

当您选择了泰国区域，您会注意到一个完全不同的年份，因为泰国使用不同的日历模型：

```powershell
$date = Get-Date
$thaiCulture = New-Object -TypeName CultureInfo("th")
$dateString = $date.ToString($thaiCulture)
$dateString
```

当您选择了一个不同的区域，Windows 也会相应地翻译并显示月份和日期名称：

```powershell
$date = Get-Date
$chineseCulture = New-Object -TypeName CultureInfo("zh")
$dateString = $date.ToString('dddd dd.MMMM yyyy',$chineseCulture)
$dateString
```

结果类似这样：

    星期三 01.十一月 2017

<!--more-->
本文国际来源：[Converting Information to Culture-Specific Text](http://community.idera.com/powershell/powertips/b/tips/posts/converting-information-to-culture-specific-text)
