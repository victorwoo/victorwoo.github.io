layout: post
date: 2015-08-13 11:00:00
title: "PowerShell 技能连载 - 删除数组元素"
description: PowerTip of the Day - Remove Array Elements
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
您曾经比较过两个数组吗？`Compare-Object` 可能有用。请试试这段代码：

    $array1 = 1..100
    $array2 = 2,4,80,98
    
    Compare-Object -ReferenceObject $array1 -DifferenceObject $array2 |
      Select-Object -ExpandProperty InputObject

执行的结果是 `$array1` 的内容减去 `$array2` 的内容。

要获取 `$array1` 和 `$array2` 中共有的元素，请使用以下方法：

    $array1 = 1..100
    $array2 = 2,4,80,98, 112
    
    Compare-Object -ReferenceObject $array1 -DifferenceObject $array2 -ExcludeDifferent -IncludeEqual |
      Select-Object -ExpandProperty InputObject

<!--more-->
本文国际来源：[Remove Array Elements](http://community.idera.com/powershell/powertips/b/tips/posts/remove-array-elements)
