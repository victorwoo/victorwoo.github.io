---
layout: post
date: 2018-06-21 00:00:00
title: "PowerShell 技能连载 - 添加前导零"
description: PowerTip of the Day - Adding Leading Zeroes
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您需要数字前面添加前导零，例如对于服务器名，以下是两种实现方式。第一，您可以将数字转换为字符串，然后用 `PadLeft()` 函数将字符串填充到指定的长度：

```powershell
$number = 76
$leadingZeroes = 8

$number.Tostring().PadLeft($leadingZeroes, '0') 

Or, you can use the -f operator:


$number = 76
$leadingZeroes = 8

"{0:d$leadingZeroes}" -f $number
```

<!--本文国际来源：[Adding Leading Zeroes](http://community.idera.com/powershell/powertips/b/tips/posts/adding-leading-zeroes)-->
