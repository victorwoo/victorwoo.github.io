layout: post
date: 2015-01-28 12:00:00
title: "PowerShell 技能连载 - 获取计算机序列号"
description: PowerTip of the Day - Getting Computer Serial Number
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

在前一个技巧里我们演示了如何通过 DELL 的序列号在线检查保修状态。其它厂家也会提供类似的服务。

这段代码可以读取序列号：

    $ComputerName = $env:COMPUTERNAME
    
    $serial = (Get-WmiObject -ComputerName $ComputerName -Class Win32_BIOS).SerialNumber
    "Your computer serial is $serial"

<!--more-->
本文国际来源：[Getting Computer Serial Number](http://community.idera.com/powershell/powertips/b/tips/posts/getting-computer-serial-number)
