---
layout: post
title: "PowerShell 技能连载 - 使用 ICACLS 提高文件夹安全性"
date: 2014-01-03 00:00:00
description: PowerTip of the Day - Using ICACLS to Secure Folders
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerShell 系统中，控制台程序也是相同的“一等公民”。在这个例子中，`New-Folder` 函数使用 `icacls.exe` 来设置新建文件夹的权限：

	function New-Folder
	{
	  param
	  (
	    $Path,
	    $Username
	  )
	
	  If ( (Test-Path -Path $path) -eq $false )
	  {
	    New-Item $path -Type Directory | Out-Null
	  }
	
	  icacls $path /inheritance:r /grant '*S-1-5-32-544:(OI)(CI)R' ('{0}:(OI)(CI)F' -f $username)
	}

`New-Folder` 函数将创建一个新文件夹（如果它不存在），然后使用 `icacls.exe` 来禁止继承、允许 Administrators 组读取以及赋予指定用户完全控制权限。

<!--本文国际来源：[Using ICACLS to Secure Folders](http://community.idera.com/powershell/powertips/b/tips/posts/using-icacls-to-secure-folders)-->
