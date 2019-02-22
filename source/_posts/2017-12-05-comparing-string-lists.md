---
layout: post
date: 2017-12-05 00:00:00
title: "PowerShell 技能连载 - 比较字符串列表"
description: PowerTip of the Day - Comparing String Lists
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个例子中我们使用 HashSet 来对比数字列表，并查找哪些元素在两个列表中都出现，或只在一个列表中出现。


字符串列表也可以做相同的事。假设您有两个名字清单，并且希望知道哪些名字在两个名单中都出现，或只在一个名单中出现，请试试以下代码：

```powershell
$set1 = New-Object System.Collections.Generic.HashSet[string] (,[string[]]@('Harry','Mary','Terri'))
$set2 = New-Object System.Collections.Generic.HashSet[string] (,[string[]]@('Tom','Tim','Terri','Tobias'))

"Original Sets:"
"$set1"
"$set2"

# in both
$copy = New-Object System.Collections.Generic.HashSet[string] $set1
$copy.IntersectWith($set2)
"In Both"
"$copy"

# combine
$copy = New-Object System.Collections.Generic.HashSet[string] $set1
$copy.UnionWith($set2)
"All Combined"
"$copy"

# exclusive
$copy = New-Object System.Collections.Generic.HashSet[string] $set1
$copy.ExceptWith($set2)
"Exclusive in Set 1"
"$copy"

# exclusive either side
$copy = New-Object System.Collections.Generic.HashSet[string] $set1
$copy.SymmetricExceptWith($set2)
"Exclusive in both (no duplicates)"
"$copy"
```

以下是执行结果：

    Original Sets:
    Harry Mary Terri
    Tom Tim Terri Tobias
    In Both
    Terri
    All Combined
    Harry Mary Terri Tom Tim Tobias
    Exclusive in Set 1
    Harry Mary
    Exclusive in both (no duplicates)
    Harry Mary Tobias Tom Tim

<!--本文国际来源：[Comparing String Lists](http://community.idera.com/powershell/powertips/b/tips/posts/comparing-string-lists)-->
