layout: post
date: 2014-12-01 12:00:00
title: "PowerShell 技能连载 - 数组中的空值"
description: PowerTip of the Day - NULL Values in Arrays
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

当您将 NULL 值赋给数组元素时，它们会记入数组元素中，但不会输出（毕竟，它们是所谓的空值）。这会导致调试时的困难。所以当数组的大小看起来和内容不一样时，请查查是否有空值：

```
$a = @()
$a += 1
$a += $null
$a += $null
$a += 2

1
2
Count: 4
```

<!--more-->
本文国际来源：[NULL Values in Arrays](http://community.idera.com/powershell/powertips/b/tips/posts/null-values-in-arrays)
