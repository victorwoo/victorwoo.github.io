---
layout: post
title: "PowerShell 技能连载 - 处理文件系统路径(第1部分)"
date: 2013-09-04 00:00:00
description: PowerTip of the Day - Manipulating File System Paths (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell允许您存取多个数组元素。通过使用 `-help` 和 `-join`，您可以很方便地通过这种方式处理多个文件系统路径。

若要排除第二层和第三层文件夹，试试以下代码：

	$path = 'C:\users\Tobias\Desktop\functions.ps1'
	$array = $path -split '\\'
	$newpath = $array[0,3,4]
	$newpath -join '\'

若要重命名第二层子文件夹，试试以下代码：

	$path = 'C:\users\Tobias\Desktop\functions.ps1'
	
	$array = $path -split '\\'
	$array[2] = 'OtherUser'
	$array -join '\'

<!--本文国际来源：[Manipulating File System Paths](http://community.idera.com/powershell/powertips/b/tips/posts/manipulating-file-system-paths)-->
