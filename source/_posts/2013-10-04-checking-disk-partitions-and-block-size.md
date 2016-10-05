layout: post
title: "PowerShell 技能连载 - 检查磁盘分区和数据块大小"
date: 2013-10-04 00:00:00
description: PowerTip of the Day - Checking Disk Partitions and Block Size
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
WMI 是一个装满信息的宝库。以下这行代码将读取本地分区以及它们的数据块大小信息：

	Get-WmiObject -Class Win32_Diskpartition  | 
	  Select-Object -Property __Server, Caption, BlockSize 

使用 `Get-WmiObject` 的 `-ComputerName` 参数可以对一台或多台机器远程执行同样的操作。

要查看其它所有的 WMI 类，您可以替换掉 `Win32_DiskPartition`，试试以下的代码：

	Get-WmiObject -Class Win32_* -List |
	  Where-Object { ($_.Qualifiers | Select-Object -ExpandProperty Name) -notcontains 'Association' } |
	  Where-Object { $_.Name -notlike '*_Perf*' }

<!--more-->

本文国际来源：[Checking Disk Partitions and Block Size](http://community.idera.com/powershell/powertips/b/tips/posts/checking-disk-partitions-and-block-size)
