---
layout: post
date: 2017-12-07 00:00:00
title: "PowerShell 技能连载 - 理解文本转换"
description: PowerTip of the Day - Understanding Text Conversions
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
有许多方法能将对象转换为文本。如果您在某些情况下弄糊涂了，这篇文章能帮您快速搞清。请看：

有三个基础的将对象转换为文本的方法。

```powershell
$a = 4.5
# simple conversion
$a.ToString()
# slightly better conversion
"$a"
# richest conversion
$a | Out-String
```

对于简单对象，三个方法的结果不会有差别。然而，对于更复杂的对象，结果差异可能很大。请看一下数组：

```powershell
$a = 1,2,3

$a.ToString()

"$a"

$a | Out-String
```

并且看看复杂对象如何转换为文本：

```powershell
$a = Get-Process

$a.ToString()

"$a"

$a | Out-String
```

<!--more-->
本文国际来源：[Understanding Text Conversions](http://community.idera.com/powershell/powertips/b/tips/posts/understanding-text-conversions)
