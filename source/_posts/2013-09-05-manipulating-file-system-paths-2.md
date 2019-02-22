---
layout: post
title: "PowerShell 技能连载 - 处理文件系统路径(第2部分)"
date: 2013-09-05 00:00:00
description: PowerTip of the Day - Manipulating File System Paths (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您将一个路径转换为数组来操作路径的各个部分时，如果您希望通过固定的数组下标来存取路径的部分，则该方法仅限于子文件夹的数量是固定的情况。

若要操作路径长度不固定的情况，试着利用变量。这个例子将会去除第1层和第2层子文件夹，无论路径有多长：

	$path = 'C:\users\Tobias\Desktop\functions.ps1'
	
	$array = $path -split '\\'
	$length = $array.Count
	$newpath = $array[,0+3..$length]
	$newpath -join '\'

请注意提取新路径的数组元素的方法：

	$newpath = $array[,0+3..$length]

这行代码取出第1个路径元素（下标为0）和第4个元素以及其之后的所有元素（下标从3开始）。

此处的奥秘是PowerShell支持多个数组下标。表达式 `x..y` 创建一个范围为x到y的数字型数组，其中x和/或y可以是变量。

当您需要增加单独的下标时，您必须将它们转化为数组，因为只有数组能被添加到数组中。这是为什么代码中下标0写成 `,0` 的原因。这样写是为了创建一个只包含0的数组，并且这个数组可以被添加到数字范围的数组，并返回一个包含所有你需要的下标的数组。

<!--本文国际来源：[Manipulating File System Paths (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/manipulating-file-system-paths-part-2)-->
