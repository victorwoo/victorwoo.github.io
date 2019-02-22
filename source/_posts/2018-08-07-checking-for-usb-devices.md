---
layout: post
date: 2018-08-07 00:00:00
title: "PowerShell 技能连载 - 检查 USB 设备"
description: PowerTip of the Day - Checking for USB Devices
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果想知道某个特定的设备是否连接到您的计算机上，您可以使用 WMI 来提取所有即插即用设备的名称：

```powershell
Get-WmiObject -Class Win32_PnpEntity | 
  Select-Object -ExpandProperty Caption
```

<!--本文国际来源：[Checking for USB Devices](http://community.idera.com/powershell/powertips/b/tips/posts/checking-for-usb-devices)-->
