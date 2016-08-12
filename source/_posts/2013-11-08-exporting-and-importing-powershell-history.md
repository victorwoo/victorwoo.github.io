layout: post
title: "PowerShell 技能连载 - 导出和导入 PowerShell 历史"
date: 2013-11-08 00:00:00
description: PowerTip of the Day - Exporting and Importing PowerShell History
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
PowerShell 保存了您键入的所有命令列表，但是当您关闭 PowerShell 时，这个列表就丢失了。

以下是一个保存当前命令历史到文件的单行代码：

	Get-History | Export-Clixml $env:temp\myHistory.xml

当您启动一个新的 PowerShell 控制台或 ISE 编辑器实例时，您可以将保存的历史读入 PowerShell：

	Import-Clixml $env:\temp\myHistory.xml | Add-History

不过，加载历史并不会影响键盘缓冲区，所以按下上下键并不会显示新导入的历史条目。然而，您可以用 TAB 自动完成功能来查找您之前输入的命令：

	#(KEYWORD) <-现在按下（TAB）键！

<!--more-->
本文国际来源：[Exporting and Importing PowerShell History](http://powershell.com/cs/blogs/tips/archive/2013/11/08/exporting-and-importing-powershell-history.aspx)
