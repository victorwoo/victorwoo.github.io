---
layout: post
title: "PowerShell 技能连载 - 查找 Cmdlet"
date: 2013-10-14 00:00:00
description: PowerTip of the Day - Finding Cmdlets
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`Get-Command` 可以用来查找 Cmdlet，但是在 PowerShell 3.0 中，它往往会返回比想象中还要多的 Cmdlet。由于自动加载模块的原因，`Get-Command` 不仅返回当前已加载 Module 中的 Cmdlet，还会返回所有可用 Module 中的 Cmdlet。

如果您仅希望在当前已加载的 Module 中查找一个 Cmdlet，请使用新的 `-ListImported` 参数：

	PS> Get-Command -Verb Get | Measure-Object
	Count    : 422
	
	PS> Get-Command -Verb Get -ListImported | Measure-Object
	Count    : 174


<!--本文国际来源：[Finding Cmdlets](http://powershell.com/cs/blogs/tips/default.aspx)-->
