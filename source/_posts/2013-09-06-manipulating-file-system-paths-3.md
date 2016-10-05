layout: post
title: "PowerShell 技能连载 - 处理文件系统路径(第3部分)"
date: 2013-09-06 00:00:00
description: PowerTip of the Day - Manipulating File System Paths (Part 3)
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
在之前介绍的技巧中我们介绍了如何将文件系统路径转化为数组，并且通过改变或排除数组的一部分元素创建一个新的路径。
您可以通过将数组转化为 `ArrayList` 类型来使其变得更简单。现在，您可以非常容易地删除现有的或增加新的路径元素。

这个例子将第一个层文件夹重命名，排除第二层子文件夹，并在第4层子文件夹之后增加一个子文件夹：

	$path = 'C:\users\Tobias\Desktop\functions.ps1'
	
	[System.Collections.ArrayList]$array = $path -split '\\'
	$array[1] = 'MyUsers'
	$array.RemoveAt(2)
	$array.Insert(3, 'NewSubFolder')
	$array.Insert(4, 'AnotherNewSubFolder')
	$array -join '\' 

结果路径是：

	C:\MyUsers\Desktop\NewSubFolder\AnotherNewSubFolder\functions.ps1

<!--more-->

本文国际来源：[Manipulating File System Paths (Part 3)](http://community.idera.com/powershell/powertips/b/tips/posts/manipulating-file-system-paths-part-3)
