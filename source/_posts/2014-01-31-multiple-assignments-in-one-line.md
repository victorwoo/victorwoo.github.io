layout: post
title: "PowerShell 技能连载 - 单行内为多个变量赋值"
date: 2014-01-31 00:00:00
description: PowerTip of the Day - Multiple Assignments in One Line
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
当您将某个值赋给一个变量时，您可以用括号把表达式括起来。这个表达式还将返回该数值。我们看看它的样子：

	$a = Get-Service
	($a = Get-Service)

见到它们的区别了吗？第二行不仅将 `Get-Service` 的结果赋值给一个变量，而且将把结果输出至控制台。

实际上您也可以利用上第二行的结果。请看如下代码：

	$b = ($a = Get-Service).Name
	$a
	$b

这将把所有的服务赋值给 `$a`，并把所有的服务名称赋值给 $b。

再次地，您可以将这个结果再用括号括起来，以供下次继续复用这个结果：

	$c = ($b = ($a = Get-Service).Name).ToUpper()
	$a
	$b
	$c

现在 `$c` 将包含所有大写形式的服务名。很另类的写法。

<!--more-->
本文国际来源：[Multiple Assignments in One Line](http://powershell.com/cs/blogs/tips/archive/2014/01/31/multiple-assignments-in-one-line.aspx)
