layout: post
title: "PowerShell 技能连载 - 通过关键词查找脚本"
date: 2013-09-30 00:00:00
description: PowerTip of the Day - Check Monitor Brightness
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
随着您硬盘上的 PowerShell 脚本数量的增多，要想找到您想要的脚本会变得越来越困难。以下是一个叫做 `Find-Script` 的工具函数。只要传入一个关键词，PowerShell 将会在您的个人文件夹下找出所有包含该关键词的脚本。

查找的结果将在一个 GridView 窗口中显示，您可以选中其中的文件，按下确认按钮以后将用 ISE 编辑器打开这些文件。

	function Find-Script
	{
	    param
	    (
	        [Parameter(Mandatory=$true)]
	        $Keyword,
	
	        $Maximum = 20,
	        $StartPath = $env:USERPROFILE
	    )
	
	    Get-ChildItem -Path $StartPath -Filter *.ps1 -Recurse -ErrorAction SilentlyContinue |
	      Select-String -SimpleMatch -Pattern $Keyword -List |
	      Select-Object -Property FileName, Path, Line -First $Maximum |
	      Out-GridView -Title 'Select Script File' -PassThru |
	      ForEach-Object { ise $_.Path }
	} 

默认情况下，`Find-Script` 只返回满足搜索条件的前 20 个脚本。您可以通过 `-Maximum` 和 `-StartPath` 参数来改变最大搜索条数和搜索位置。
<!--more-->

本文国际来源：[Finding Scripts by Keyword](http://powershell.com/cs/blogs/tips/archive/2013/09/30/finding-scripts-by-keyword.aspx)
