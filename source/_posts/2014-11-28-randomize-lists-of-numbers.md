---
layout: post
date: 2014-11-28 12:00:00
title: "PowerShell 技能连载 - 随机排列数字列表"
description: PowerTip of the Day - Randomize Lists of Numbers
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

这行代码将输入一个数字列表并对它们随机排序：

```
Get-Random -InputObject 1, 2, 3, 5, 8, 13 -Count ([int]::MaxValue)
```

也可以用管道，不过速度更慢：

```
1, 2, 3, 5, 8, 13 | Sort-Object -Property { Get-Random }
```

<!--more-->
本文国际来源：[Randomize Lists of Numbers](http://community.idera.com/powershell/powertips/b/tips/posts/randomize-lists-of-numbers)
