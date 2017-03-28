layout: post
title: "PowerShell 技能连载 - 消除重复"
date: 2014-03-04 00:00:00
description: PowerTip of the Day - Eliminating Duplicates
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
`Sort-Object` 有一个很棒的特性：使用 `-Unique` 参数，您可以移除重复对象：

![](/img/2014-03-04-eliminating-duplicates-001.png)

这也可以用于对象类型的结果。请看这个例子，它将从您的系统事件日志中获取最后的 40 条错误：

![](/img/2014-03-04-eliminating-duplicates-002.png)

它的结果也许完全正确，但是您实际上可能得到很多重复的条目。

通过使用 `-Unique` 参数，您可以基于多个属性消除重复的结果：

![](/img/2014-03-04-eliminating-duplicates-003.png)

这样，您再也看不到多于一条具有相同 InstanceID **和** 消息的结果了。

您可以再次对结果排序，以使得结果按时间排序。

![](/img/2014-03-04-eliminating-duplicates-004.png)

所以结论是：`Sort-Objects` 的 `-Unique` 参数可以一次性应用到多个属性上。

<!--more-->
本文国际来源：[Eliminating Duplicates](http://community.idera.com/powershell/powertips/b/tips/posts/eliminating-duplicates)
