---
layout: post
date: 2017-03-28 00:00:00
title: "PowerShell 技能连载 - 使用通配符确定数组是否包含值"
description: "PowerTip of the Day - Determine if Array Contains Value – Using Wildcards"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您想了解一个数组是否包含某个指定的元素，PowerShell 提供了 `-contains` 操作符。然而这个操作符不支持通配符，所以您只能使用精确匹配。

以下是一个帮助您使用通配符过滤数组元素的解决方法：

```powershell
$a = 'Hanover', 'Hamburg', 'Vienna', 'Zurich'

# is the exact phrase present in array?
$a -contains 'Hannover'
# is ANY phrase present in array that matches the wildcard expression?
(@($a) -like 'Ha*').Count -gt 0

# list all phrases from array that match the wildcard expressions
@($a) -like 'Ha*'
```

<!--本文国际来源：[Determine if Array Contains Value – Using Wildcards](http://community.idera.com/powershell/powertips/b/tips/posts/determine-if-array-contains-value-using-wildcards)-->
