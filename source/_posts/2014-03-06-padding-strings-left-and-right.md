---
layout: post
title: "PowerShell 技能连载 - 字符串左右对齐"
date: 2014-03-06 00:00:00
description: PowerTip of the Day - Padding Strings Left and Right
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
如果您需要确保给定的字符串有一致的宽度，那么您可以使用 .NET 方法来适当地对齐字符串：

    $mytext = 'Test'
    
    $paddedText = $mytext.PadLeft(15)
    "Here is the text: '$paddedText'"
    
    $paddedText = $mytext.PadRight(15)
    "Here is the text: '$paddedText'" 

以下是结果：

![](/img/2014-03-06-padding-strings-left-and-right-001.png)

您甚至可以自己指定补充的字符（如果您不想使用空格来补的话）：

![](/img/2014-03-06-padding-strings-left-and-right-002.png)

<!--more-->
本文国际来源：[Padding Strings Left and Right](http://community.idera.com/powershell/powertips/b/tips/posts/padding-strings-left-and-right)
