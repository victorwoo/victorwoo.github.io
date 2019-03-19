---
layout: post
title: "PowerShell 技能连载 - 在文件管理器中显示隐藏文件"
date: 2013-09-20 00:00:00
description: PowerTip of the Day - Showing Hidden Files in File Explorer
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell可以方便地读写注册表。注册表是Windows设置的中心仓库。

这是一个可以设置文件管理器显示/不显示隐藏文件的函数。它聪明的地方在于不需要向注册表写入新值。它相当于文件管理器窗口如何显示和改变它们的内容。

	function Show-HiddenFile
	{
	    param([Switch]$Off)

	    $value = -not $Off.IsPresent
	    Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced `
	    -Name Hidden -Value $value -type DWORD

	    $shell = New-Object -ComObject Shell.Application
	    $shell.Windows() |
	        Where-Object { $_.document.url -eq $null } |
	        ForEach-Object { $_.Refresh() }
	}

`Show-HiddenFile` 使得隐藏文件变得可见；而 `Show-HiddenFile -Off` 使得隐藏文件不可见。操作结果几乎在所有文件管理窗口中立即生效。如果您在没有打开文件管理窗口的情况下做出改变，则改变不会立即生效，因为没有可以调用 `Refresh()` 方法的窗口。

<!--本文国际来源：[Showing Hidden Files in File Explorer](http://community.idera.com/powershell/powertips/b/tips/posts/showing-hidden-files-in-file-explorer)-->
