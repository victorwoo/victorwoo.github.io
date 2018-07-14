---
layout: post
date: 2018-07-11 00:00:00
title: "PowerShell 技能连载 - 交换变量值"
description: PowerTip of the Day - Exchanging Variable Values
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
以下是一个在一行代码中交换变量内容的快速技能：

```powershell
$a = 1
$b = 2

# switch variable content
$a, $b = $b, $a

$a
$b
```

<!--more-->
本文国际来源：[Exchanging Variable Values](http://community.idera.com/powershell/powertips/b/tips/posts/exchanging-variable-values)
