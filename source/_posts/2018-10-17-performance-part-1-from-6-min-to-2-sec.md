---
layout: post
date: 2018-10-17 00:00:00
title: "PowerShell 技能连载 - 性能（第 1 部分）：从 6 分钟到 2 秒钟"
description: 'PowerTip of the Day - Performance (Part 1): From 6 min to 2 sec'
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
以下是一个在许多 PowerShell 脚本中常见的错误：

```powershell
$start = Get-Date

$bucket = @()

1..100000 | ForEach-Object {
    $bucket += "I am adding $_"
}

$bucket.Count

(Get-Date) - $start
```

在这个设计中，脚本使用了一个空的数组，然后用某种循环向数组中增加元素。当运行它的时候，会发现它停不下来。实际上这段代码在我们的测试系统中需要超过 6 分钟时间，甚至有可能在您的电脑上要消耗更多时间。

以下是导致缓慢的元凶：对数组使用操作符 "`+=`" 是有问题的。因为每次使用 "`+=`" 时，它表面上动态扩展了该数组，实际上却是创建了一个元素数量更多一个的新数组。

要显著地提升性能，请让 PowerShell 来创建数组：当返回多个元素时，PowerShell 自动高速创建数组：

```powershell
$start = Get-Date

$bucket = 1..10000 | ForEach-Object {
    "I am adding $_"
}

$bucket.Count

(Get-Date) - $start
```

结果完全相同，但和消耗 6+ 分钟不同的是，它在 PowerShell 5.1 上只用了 46 秒钟，而在 PowerShell 6.1 上仅仅用了 1.46 秒。我们将会用另一个技巧来进一步提升性能。

<!--more-->
本文国际来源：[Performance (Part 1): From 6 min to 2 sec](http://community.idera.com/powershell/powertips/b/tips/posts/performance-part-1-from-6-min-to-2-sec)
