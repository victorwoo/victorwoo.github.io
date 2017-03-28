layout: post
title: "PowerShell 技能连载 - 查找空闲容量低的硬盘驱动器"
date: 2014-03-13 00:00:00
description: PowerTip of the Day - Finding Hard Drives Running Low on Storage
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
可以通过 WMI 轻松地获取驱动器信息。以下代码可以从您的本地计算机中获取驱动器信息（用 `-ComputerName` 可以存取远程系统的信息）。

![](/img/2014-03-13-finding-hard-drives-running-low-on-storage-001.png)

![](/img/2014-03-13-finding-hard-drives-running-low-on-storage-002.png)

要限制结果只包含硬盘驱动器，并且只包含空闲容量低于指定值的硬盘驱动器，请试试以下代码：

    $limit = 80GB
    Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3 and Freespace<$limit" | 
      Select-Object -Property VolumeName, Freespace, DeviceID 

<!--more-->
本文国际来源：[Finding Hard Drives Running Low on Storage](http://community.idera.com/powershell/powertips/b/tips/posts/finding-hard-drives-running-low-on-storage)
