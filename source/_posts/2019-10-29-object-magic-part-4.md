---
layout: post
date: 2019-10-29 00:00:00
title: "PowerShell 技能连载 - 对象的魔法（第 4 部分）"
description: PowerTip of the Day - Object Magic (Part 4)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
将一个对象转换为一个哈希表如何？通过这种方式，当将对象输出到一个网格视图窗口时，可以每行显示一个对象属性：

```powershell
# get any object
$object = Get-Process -Id $pid

# try and access the PSObject
$hash = $object.PSObject.Properties.Where{$null -ne $_.Value}.Name |
    Sort-Object |
    ForEach-Object { $hash = [Ordered]@{} } { $hash[$_] = $object.$_ } { $hash }

# output regularly
$object | Out-GridView -Title Regular

# output as a hash table, only non-empty properties, sorted
$hash | Out-GridView -Title Hash
```

<!--本文国际来源：[Object Magic (Part 4)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/object-magic-part-4)-->

