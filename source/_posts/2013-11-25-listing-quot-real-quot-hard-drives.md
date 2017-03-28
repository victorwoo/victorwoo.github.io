layout: post
title: "PowerShell 技能连载 - 列出“真实”的硬盘"
date: 2013-11-25 00:00:00
description: PowerTip of the Day - Listing Real Hard Drives
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
WMI 可以提供一个系统的很多信息，但是有些时候这些信息太多了。当您查询逻辑磁盘时，您得到的往往不止是物理磁盘。

设置额外的过滤器可以解决此问题。以下这行代码通过设置 `DriveType=3` 来获取物理驱动器：

	PS> Get-WmiObject -Class Win32_LogicalDisk -Filter 'DriveType=3'
	
	DeviceID     : C:
	DriveType    : 3
	ProviderName : 
	FreeSpace    : 4468535296
	(...)

由于 `Get-WmiObject` 有一个 `-ComputerName` 参数，所以您也可以远程获取该信息。如果您想知道有哪些其他的驱动器类型，只需要去掉过滤条件，或者用搜索引擎搜索 `"Win32_LogicalDisk DriveType"`。

<!--more-->
本文国际来源：[Listing "Real" Hard Drives](http://community.idera.com/powershell/powertips/b/tips/posts/listing-quot-real-quot-hard-drives)
