---
layout: post
date: 2018-09-19 00:00:00
title: "PowerShell 技能连载 - 解析映射驱动器"
description: PowerTip of the Day - Resolving Mapped Drive
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
是否想知道网络驱动器背后的原始 URL？以下是一个简单的 PowerShell 方法：

```powershell
# make sure the below drive is a mapped network drive
# on your computer
$mappedDrive = 'z'


$result = Get-PSDrive -Name $mappedDrive |
    Select-Object -ExpandProperty DisplayRoot

"$mappedDrive -> $result"
```

<!--more-->
本文国际来源：[Resolving Mapped Drive](http://community.idera.com/powershell/powertips/b/tips/posts/resolving-mapped-drive)
