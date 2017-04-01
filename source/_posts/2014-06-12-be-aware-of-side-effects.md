layout: post
title: "PowerShell 技能连载 - 留意副作用"
date: 2014-06-12 00:00:00
description: PowerTip of the Day - Be Aware of Side Effects
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
PowerShell 可以使用许多底层的系统函数。例如这个，可以创建一个临时文件名：

	[System.IO.Path]::GetTempFileName()

然而，它不仅只做这一件事。它还真实地创建了那个文件。所以如果您使用这个函数来创建临时文件名，您可能最终会在文件系统中创建一堆孤立的文件。请在您的确需要创建一个临时文件的时候才使用它。

<!--more-->
本文国际来源：[Be Aware of Side Effects](http://community.idera.com/powershell/powertips/b/tips/posts/be-aware-of-side-effects)
