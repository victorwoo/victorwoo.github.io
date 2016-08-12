layout: post
title: "PowerShell 技能连载 - 降低 PowerShell 进程优先级"
date: 2014-01-02 00:00:00
description: PowerTip of the Day - Lowering PowerShell Process Priority
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
当您运行一个 PowerShell 任务时，默认情况下它的优先级是 Normal。并且如果您脚本所做的事十分消耗 CPU 的话，您机器的性能可能会受影响。

要避免这个现象，您可以将您的 PowerShell 进程设置为更低的优先级，这样它仅在 CPU 负载允许的情况下运行。这可以确保您的 PowerShell 任务不会影响其它任务的性能。

这个例子将优先级设为“Below Normal”。您也可以将它设置为“Idle”，那样您的 PowerShell 脚本仅当机器没有别的事做时才会运行。

	$process = Get-Process -Id $pid
	$process.PriorityClass = 'BelowNormal'

> 译者注：可能的 PriorityClass 值为 `Normal`、`Idle`、`High`、`RealTime`、`BelowNormal`、`AboveNormal`。
> 要找到明确的文档比较困难，但是有一个取巧的办法：故意打错。比如说我们可以打成 `$process.PriorityClass = 'trudellic'`，运行以后提示：
>
	Exception setting "PriorityClass": "Cannot convert value "trudellic" to type
	"System.Diagnostics.ProcessPriorityClass". 
	Error: "Unable to match the identifier name trudellic to a valid enumerator name.

> 这时候可用的值在错误提示中就暴露出来了 :-)  

<!--more-->
本文国际来源：[Lowering PowerShell Process Priority](http://powershell.com/cs/blogs/tips/archive/2014/01/02/lowering-powershell-process-priority.aspx)
