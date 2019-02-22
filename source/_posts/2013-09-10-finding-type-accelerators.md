---
layout: post
title: "PowerShell 技能连载 - 查找类型加速器"
date: 2013-09-10 00:00:00
description: PowerTip of the Day - Finding Type Accelerators
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell维护着一系列.NET类型的缩写，使您编写代码更加自如。例如要将一个字符串转换成DateTime类型，您可以这样写：

	[DateTime] '2013-07-02'

它的幕后机制只是一个名为 `System.DateTime` 类型的缩写。您可以通过 `FullName` 属性查看这些缩写实际上代表的类型：

	[DateTime].FullName

若要获取所有支持的“类型加速器”（缩写），您可以使用以下代码。这段代码返回PowerShell实现的所有加速器。这段代码十分有用，因为它列出了PowerShell开发者认为十分重要的所有.NET内部类型。

	[PSObject].Assembly.GetType("System.Management.Automation.TypeAccelerators")::Get |
		Sort-Object -Property Value 

当您将结果通过管道输出到一个grid view窗口时，您可以方便地搜索类型加速器。只需要在grid view窗口顶部的搜索框内键入类型名的一部分即可：

	[PSObject].Assembly.GetType("System.Management.Automation.TypeAccelerators")::Get |
		Sort-Object -Property Value |
		Out-GridView


<!--本文国际来源：[Finding Type Accelerators](http://community.idera.com/powershell/powertips/b/tips/posts/finding-type-accelerators)-->
