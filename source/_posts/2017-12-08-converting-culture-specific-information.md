---
layout: post
date: 2017-12-08 00:00:00
title: "PowerShell 技能连载 - 转换区域性特定的信息"
description: PowerTip of the Day - Converting Culture-Specific Information
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
假设您以文本的形式收到了数字或日期等数据。当信息转为文本的时候，您会遇到区域性特定的格式：不同区域的小数点和日期时间可能会不同。

以下是一个如何解析数据的简单例子，假设您知道它的来源区域信息：

```powershell
# number in German format
$info = '1,2'

# convert to real value
$culture = New-Object -TypeName CultureInfo("de")
$number = [Double]::Parse($info,$culture)
```

每一个目标类型有一个 `Parse()` 方法，所以如果您收到一个日期和/或时间信息，您可以将它如此简单地转换它。这个例子输入的是以法国标准格式化的日期和时间，并返回一个真正的 `DateTime` 对象：

```powershell
# date and time in French format:
$info = '01/11/2017 16:28:45'

# convert to real value
$culture = New-Object -TypeName CultureInfo("fr")
$date = [DateTime]::Parse($info,$culture)
$date
```

<!--more-->
本文国际来源：[Converting Culture-Specific Information](http://community.idera.com/powershell/powertips/b/tips/posts/converting-culture-specific-information)
