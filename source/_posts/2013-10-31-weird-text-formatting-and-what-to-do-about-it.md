---
layout: post
title: "PowerShell 技能连载 - 怪异的文本格式化（以及解决方法）"
date: 2013-10-31 00:00:00
description: PowerTip of the Day - Weird Text Formatting (and what to do about it)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
试试以下的代码并且找到问题所在：

	$desc = Get-Process -Id $pid | Select-Object -Property Description
	"PowerShell process description: $desc"

这段代码的目的是获取 PowerShell 宿主进程并且读取进程的描述信息，然后输出到字符串。它的结果看起来是怪异的：

	PowerShell process description: @{Description=Windows PowerShell}

这是因为代码中选择了整个 Description 属性，而且结果不仅是描述字符串，而且包括了整个属性：

	PS> $desc

	Description
	-----------
	Windows PowerShell ISE

当您只选择一个属性时，请确保使用 `-ExpandProperty` 而不是 `-Property`。前者避免产生一个属性列，并且字符串看起来正常了：

	PS> $desc = Get-Process -Id $pid | Select-Object -ExpandProperty Description
	PS> "PowerShell process description: $desc"
	PowerShell process description: Windows PowerShell ISE

<!--本文国际来源：[Weird Text Formatting (and what to do about it)](http://community.idera.com/powershell/powertips/b/tips/posts/weird-text-formatting-and-what-to-do-about-it)-->
