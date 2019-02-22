---
layout: post
date: 2015-10-05 11:00:00
title: "PowerShell 技能连载 - 获取最后启动时间"
description: PowerTip of the Day - Getting Last Bootup Time
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerShell 3.0 以上版本中，可以很容易地用 `Get-CimInstance` 从 WMI 中获取真实的 DateTime 类型信息。这段代码将告诉您系统上次启动的时间：

    #requires -Version 3
    (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime

在 PowerShell 2.0 中，您只能使用 `Get-WmiObject`，它是以 WMI 格式反馈数据的：

    (Get-WmiObject -Class Win32_OperatingSystem).LastBootUpTime

这里，您必须手工转换 WMI 格式：

    $object = Get-WmiObject -Class Win32_OperatingSystem
    $lastboot = $object.LastBootUpTime
    $object.ConvertToDateTime($lastboot)

`ConvertToDateTime()` 转换函数实际上是一个附加的方法。在这个场景背后，是一个静态方法实现了以上工作：

    $object = Get-WmiObject -Class Win32_OperatingSystem
    $lastboot = $object.LastBootUpTime
    [System.Management.ManagementDateTimeConverter]::ToDateTime($lastboot)

<!--本文国际来源：[Getting Last Bootup Time](http://community.idera.com/powershell/powertips/b/tips/posts/getting-last-bootup-time)-->
