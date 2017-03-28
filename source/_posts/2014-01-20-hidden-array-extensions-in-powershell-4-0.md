layout: post
title: "PowerShell 技能连载 - PowerShell 4.0 中隐藏的数组扩展方法"
date: 2014-01-20 00:00:00
description: PowerTip of the Day - Hidden Array Extensions in PowerShell 4.0
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
PowerShell 4.0 （Windows 8.1 自带）中的数组原生支持 Foreach 和 Where 操作。这是一个 geek 的写法，所以并不见得比传统的管道有明显的优势（除了也许性能有所提升之外）。

这行代码将从一个数字列表中过滤出奇数来：

	@(1..10).Where({$_ % 2})

以下代码将获取正在运行中的服务：

	@(Get-Service).Where({$_.Status -eq 'Running'})

还有一些更多的（不在文档中）的东西。这行代码将获取大于 2 的前 4 个数字：

	@(1..10).Where({$_ -gt 2}, 'skipuntil', 4)

最后，以下代码将做类似的事情，但是将它们转换为 TimeSpan 对象：

	@(1..10).Where({$_ -gt 2}, 'skipuntil', 5).Foreach([Timespan])

<!--more-->
本文国际来源：[Hidden Array Extensions in PowerShell 4.0](http://community.idera.com/powershell/powertips/b/tips/posts/hidden-array-extensions-in-powershell-4-0)
