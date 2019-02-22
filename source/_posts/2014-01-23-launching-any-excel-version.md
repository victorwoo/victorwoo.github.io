---
layout: post
title: "PowerShell 技能连载 - 启动任何版本的 Excel"
date: 2014-01-23 00:00:00
description: PowerTip of the Day - Launching Any Excel Version
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Microsoft Excel 是一个不那么容易直接运行的程序的例子：Excel 的路径也许是各不相同的，取决于 Office 的版本以及平台的架构（32 位或 64 位）。

PowerShell 有一个十分智能的 cmdlet 来用于运行程序：`Start-Process`。通常您可以以这种方式用它来运行 Excel（或其它可执行程序）：

	PS> Start-Process -FilePath 'C:\Program Files (x86)\Microsoft Office\Office14\EXCEL.EXE'

而在您的系统中， Excel 的路径可能不同。这是为什么 Start-Process 设计成接受通配符的原因。只要将路径中所有“特定的”部分替换为一个通配符即可。

以下代码将会运行任何版本的 Excel，而不论是什么平台架构：

	PS> Start-Process -FilePath 'C:\Program*\Microsoft Office\Office*\EXCEL.EXE'

<!--本文国际来源：[Launching Any Excel Version](http://community.idera.com/powershell/powertips/b/tips/posts/launching-any-excel-version)-->
