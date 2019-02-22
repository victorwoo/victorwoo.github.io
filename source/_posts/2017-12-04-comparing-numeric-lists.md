---
layout: post
date: 2017-12-04 00:00:00
title: "PowerShell 技能连载 - 比较数字列表"
description: PowerTip of the Day - Comparing Numeric Lists
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
一个脚本常常需要对比两个列表是否相等，或者某个列表是否缺失了某个元素。这种情况下，您可以使用 `HashSet`，而不用手动写代码。请看：

```powershell
$set1 = New-Object System.Collections.Generic.HashSet[int32] (,[int[]]@(1,2,5,7,9,12))
$set2 = New-Object System.Collections.Generic.HashSet[int32] (,[int[]]@(1,2,5,12,111))

"Original Sets:"
"$set1"
"$set2"

# in both
$copy = New-Object 'System.Collections.Generic.HashSet[int32]' $set1
$copy.IntersectWith($set2)
"In Both"
"$copy"

# combine
$copy = New-Object 'System.Collections.Generic.HashSet[int32]' $set1
$copy.UnionWith($set2)
"All Combined"
"$copy"

# exclusive
$copy = New-Object 'System.Collections.Generic.HashSet[int32]' $set1
$copy.ExceptWith($set2)
"Exclusive in Set 1"
"$copy"

# exclusive either side
$copy = New-Object 'System.Collections.Generic.HashSet[int32]' $set1
$copy.SymmetricExceptWith($set2)
"Exclusive in both (no duplicates)"
"$copy"
```

这个例子演示了如何创建两个初始的集合：`$set1` 和 `$set2`。

要计算一个列表和另一个列表的差别，首先创建一个列表的工作拷贝，然后可以运用各种比较方法，将工作拷贝和另一个列表做比较。

结果可以在工作拷贝中直接查看。这是以上代码的执行结果：

    Original Sets:
    1 2 5 7 9 12
    1 2 5 12 111
    In Both
    1 2 5 12
    All Combined
    1 2 5 7 9 12 111
    Exclusive in Set 1
    7 9
    Exclusive in both (no duplicates)
    7 9 111

<!--本文国际来源：[Comparing Numeric Lists](http://community.idera.com/powershell/powertips/b/tips/posts/comparing-numeric-lists)-->
