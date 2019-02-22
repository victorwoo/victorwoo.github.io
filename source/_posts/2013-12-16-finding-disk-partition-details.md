---
layout: post
title: "PowerShell 技能连载 - 查找磁盘分区详细信息"
date: 2013-12-16 00:00:00
description: PowerTip of the Day - Finding Disk Partition Details
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
要查看磁盘分区信息，请使用 WMI：

	Get-WmiObject -Class Win32_DiskPartition |
	  Select-Object -Property *

然后，选择您感兴趣的属性，然后将 `*` 号替换成逗号分隔的属性列表。例如：

	Get-WmiObject -Class Win32_DiskPartition |
	  Select-Object -Property Name, BlockSize, Description, BootPartition

如果您选择四个或四个以下的属性，结果是一个干净的表格，否则将是一个列表：

![](/img/2013-12-16-finding-disk-partition-details-001.png)

如果您想知道更多的信息，请使用 `-List` 参数来搜索其它 WMI 类，或者和 "disk" 有关的，或者其它完全不相关的：

![](/img/2013-12-16-finding-disk-partition-details-002.png)

<!--本文国际来源：[Finding Disk Partition Details](http://community.idera.com/powershell/powertips/b/tips/posts/finding-disk-partition-details)-->
