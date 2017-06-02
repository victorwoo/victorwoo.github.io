---
layout: post
title: "PowerShell 技能连载 - 增加新的类型加速器"
date: 2013-09-11 00:00:00
description: PowerTip of the Day - Adding New Type Accelerators in Powershell
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
如果您发现您常常使用某些.NET类型，您可能会希望创建一些快捷方式，使您的生活变得更简单。

例如，`System.IO.Path` .NET类型有许多常用的路径功能：

	[System.IO.Path]::GetExtension('c:\test.txt')
	[System.IO.Path]::ChangeExtension('c:\test.txt', 'bak')

如果您觉得每次为了这个.NET类型敲入长长的代码太辛苦，只需要用这种方式增加一个快捷方式：

	[PSObject].Assembly.GetType("System.Management.Automation.TypeAccelerators")::Add('Path', [System.IO.Path])

现在，您可以通过 `Path` 快捷方式获得完全一样的功能：

	[Path]::GetExtension('c:\test.txt')
	[Path]::ChangeExtension('c:\test.txt', 'bak')

要查看一个类型所支持的所有方法和属性，用以下的代码：

	[Path] | Get-Member -Static

<!--more-->

本文国际来源：[Adding New Type Accelerators in Powershell](http://community.idera.com/powershell/powertips/b/tips/posts/adding-new-type-accelerators-in-powershell)
