layout: post
date: 2016-12-19 00:00:00
title: "PowerShell 技能连载 - 系统内存、单位和四舍五入"
description: PowerTip of the Day - System Memory, Units, and Rounding
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
有些时候，您可能会需要不同的度量单位。例如整个系统的内存是以字节计算的。以下是一些将字节转换为 GB 并且仍然保证可读性的例子：

```powershell
$memory = Get-WmiObject -Class Win32_ComputerSystem | 
  Select-Object -ExpandProperty TotalPhysicalMemory

$memoryGB = $memory/1GB

# raw result in bytes
$memoryGB

# rounding
[Int]$memoryGB
[Math]::Round($memoryGB)
[Math]::Round($memoryGB, 1)

# string formatting
'{0:n1} GB' -f $memoryGB
```

结果看起来类似如下：


    15.8744087219238
    16
    16
    15.9
    15.9 GB

<!--more-->
本文国际来源：[System Memory, Units, and Rounding](http://community.idera.com/powershell/powertips/b/tips/posts/system-memory-units-and-rounding)
