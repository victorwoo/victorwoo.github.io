layout: post
title: "PowerShell 技能连载 - 创建一个文件夹选择器"
date: 2013-12-09 00:00:00
description: PowerTip of the Day - Create a Folder Selector
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
问了让您的脚本增加一些魅力，以下几行代码可以显示一个文件夹选择对话框。当用户选择了一个文件夹，您的脚本可以接收到选择的结果并且可以获得选择的路径：

	Add-Type -AssemblyName System.Windows.Forms
	[System.Windows.Forms.Application]::EnableVisualStyles()
	
	$FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
	$null = $FolderBrowser.ShowDialog()
	$Path = $FolderBrowser.SelectedPath
	
	"You selected: $Path"

请注意前两行：当您在 ISE 编辑器中运行代码时不需要它们，但当您从 powershell.exe 中运行代码时需要它们。所以我们保留着两行来确保您的代码在各个 PowerShell 宿主中都能有效运行。

<!--more-->
本文国际来源：[Create a Folder Selector](http://community.idera.com/powershell/powertips/b/tips/posts/create-a-folder-selector)
