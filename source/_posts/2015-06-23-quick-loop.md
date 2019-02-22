---
layout: post
date: 2015-06-23 11:00:00
title: "PowerShell 技能连载 - 快捷循环"
description: PowerTip of the Day - Quick Loop
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell 4.0 及以上版本_

PowerShell 中有一系列循环的语法。以下是一些 PowerShell 4.0 中循环执行代码的不太常见的方法。这个例子将播放一段频率不断提高的声音（请确保打开了扬声器）：

    (1..100).Foreach{[Console]::Beep($_ * 100, 300)}

在 PowerShell 4.0 及以上版本，数组拥有了 `Where()` 和 `ForEach()` 方法。您可以像这样写一个过滤器：

    @(Get-Service).Where({$_.Status -eq 'Running'})

PowerShell 的语法糖能让您省略这些语句中的大括号：

    @(Get-Service).Where{$_.Status -eq 'Running'}

请注意该方法是针对数组的。相对于传统的管道方法，这种方法速度更快，但是内存消耗更大。

<!--本文国际来源：[Quick Loop](http://community.idera.com/powershell/powertips/b/tips/posts/quick-loop)-->
