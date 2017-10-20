---
layout: post
date: 2017-10-17 00:00:00
title: "PowerShell 技能连载 - 确定启动时间点和启动以来的时间"
description: PowerTip of the Day - Determine Boot Time and Uptime
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
WMI 可以告诉您系统是什么时候启动的，还可以利用这个信息计算启动以来经历的时间：

```powershell
$bootTime = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -ExpandProperty LastBootupTime
$upTime = New-TimeSpan -Start $bootTime

$min = [int]$upTime.TotalMinutes
"Your system is up for $min minutes now."
```

请注意当使用 `-ComputerName` 访问远程系统时，`Get-CimInstance` 默认使用 WinRM 远程处理。旧的系统可能没有启用 WinRM 远程处理，而仍然使用 DCOM 技术。

<!--more-->
本文国际来源：[Determine Boot Time and Uptime](http://community.idera.com/powershell/powertips/b/tips/posts/determine-boot-time-and-uptime)
