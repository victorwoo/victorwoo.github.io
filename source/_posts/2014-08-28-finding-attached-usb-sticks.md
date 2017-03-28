layout: post
date: 2014-08-28 11:00:00
title: "PowerShell 技能连载 - 查找插入的 U 盘"
description: PowerTip of the Day - Finding Attached USB Sticks
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
_适用于 PowerShell 所有版本_

如果您想知道是否有已插入电脑的 USB 存储设备，那么 WMI 可以做到：

    Get-WmiObject -Class Win32_PnPEntity |
      Where-Object { $_.DeviceID -like 'USBSTOR*' } 

这将返回所有“`USBSTOR`”类的即插即用设备。

如果您想用 WMI 查询语言（WQL），您还可以用命令过滤器来实现：

    Get-WmiObject -Query 'Select * From Win32_PnPEntity where DeviceID Like "USBSTOR%"'

<!--more-->
本文国际来源：[Finding Attached USB Sticks](http://community.idera.com/powershell/powertips/b/tips/posts/finding-attached-usb-sticks)
