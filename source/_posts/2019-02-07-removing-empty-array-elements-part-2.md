---
layout: post
date: 2019-02-07 00:00:00
title: "PowerShell 技能连载 - 移除空的数组元素（第 2 部分）"
description: PowerTip of the Day - Removing Empty Array Elements (Part 2)
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
如果您想彻底移除空的数组元素（而不需要关心任何空属性），以下是一些性能根本不同的几种实现：

```powershell
# create huge array with empty elements
$array = 1,2,3,$null,5,0,3,1,$null,'',3,0,1
$array = $array * 1000

# "traditional" approach (6 sec)
Measure-Command {
    $newArray2 = $array | Where-Object { ![string]::IsNullOrWhiteSpace($_) }
}

# smart approach (0.03 sec)
Measure-Command {
    $newArray3 = foreach ($_ in $array) { if (![String]::IsNullOrWhiteSpace($_)){ $_} }
}
```

<!--more-->
本文国际来源：[Removing Empty Array Elements (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/removing-empty-array-elements-part-2)
