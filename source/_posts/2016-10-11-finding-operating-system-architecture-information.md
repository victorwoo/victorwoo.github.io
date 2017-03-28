layout: post
date: 2016-10-11 00:00:00
title: "PowerShell 技能连载 - 查找操作系统架构信息"
description: PowerTip of the Day - Finding Operating System Architecture Information
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
这是获取您操作系统信息的一行代码：

```powershell
Get-WmiObject -Class Win32_OperatingSystem | Select-Object -Property *OS*
```

结果看起来类似如下：

```
ForegroundApplicationBoost : 2
OSArchitecture             : 64-bit
OSLanguage                 : 1031
OSProductSuite             : 256
OSType                     : 18
```

如果您想知道这些数字代表什么意思，可以在网上搜索 `Win32_OperatingSystem` 第一个链接就会引导您到对应的 MSDN 文档。

如果您想从一个远程系统中获取信息，请使用 `-ComputerName` 和 `–Credential` 参数。

<!--more-->
本文国际来源：[Finding Operating System Architecture Information](http://community.idera.com/powershell/powertips/b/tips/posts/finding-operating-system-architecture-information)
