layout: post
title: "PowerShell 技能连载 - 监测日志文件"
date: 2013-11-15 00:00:00
description: PowerTip of the Day - Monitoring Log Files
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
从 PowerShell 3.0 开始，实时监测基于文本的日志文件变得很容易。试试以下代码：

	$Path = "$home\Desktop\testfile.txt"
	
	'Test' | Out-File "$home\Desktop\testfile.txt"
	notepad $Path
	
	Get-Content -Path $Path -Tail 0 -Wait | Out-GridView -Title $Path

这段代码将在桌面上创建一个文本文件，然后在记事本中打开它。然后 PowerShell 将开始监视文件的变化。一旦您向记事本窗口键入新的文本并保存，则变化的部分会呈现在 PowerShell 的网格视图中。 

要监视另一个基于文本的日志文件，只需要改变路径参数即可。由于 PowerShell 在监视文件的状态下处于阻塞状态，您可能需要在另一个 PowerShell 实例中执行新的代码。

> 译者注：`Get-Content -Tail` 的效果和 Linux 下的 `tail -f` 命令的执行效果一致。但 PowerShell 是面向 .NET 对象的，可以利用管道和其它命令，例如 `Out-GridView` 配合，更为强大。

<!--more-->
本文国际来源：[Monitoring Log Files](http://community.idera.com/powershell/powertips/b/tips/posts/monitoring-log-files)
