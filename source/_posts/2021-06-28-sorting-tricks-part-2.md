---
layout: post
date: 2021-06-28 00:00:00
title: "PowerShell 技能连载 - 排序技巧（第 2 部分）"
description: PowerTip of the Day - Sorting Tricks (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技能中，我们展示了 Sort-Object 如何对多个属性进行排序，以及如何使用哈希表分别控制每个属性的排序方向。不过，哈希表还可以做更多的事情。

例如，哈希表键 "`Expression`" 可以是一个脚本块，然后针对您要排序的每个项目执行该脚本块。脚本块的结果决定了排序顺序。

这就是为什么这行代码每次都会以不同的方式重新排列数字列表：

```powershell
1..10 | Sort-Object -Property @{Expression={ Get-Random }}
```

本质上，本示例使用 `Get-Random` 的随机结果对数字列表进行随机排序。这可能很有用，即当您使用密码生成器并希望随机分配脚本计算的字符时：

```powershell
# compose password out of these
$Capitals = 2
$Numbers = 1
$lowerCase = 3
$Special = 1

# collect random chars from different lists in $chars
$chars = & {
    'ABCDEFGHKLMNPRSTUVWXYZ'.ToCharArray() | Get-Random -Count $Capitals
    '23456789'.ToCharArray() | Get-Random -Count $Numbers
    'abcdefghkmnprstuvwxyz'.ToCharArray() | Get-Random -Count $lowerCase
    '!§$%&?=#*+-'.ToCharArray() | Get-Random -Count $Special
} | # <- don't forget pipeline symbol!
# sort them randomly
Sort-Object -Property { Get-Random }

# convert chars to one string
$password =  -join $chars
$password
```

正如您在实际示例中看到的，`Sort-Object` 还接受一个简单的脚本块，它表示哈希表的 "`Expression`" 键。两行的工作方式相同（但当然会产生不同的随机结果）：

```powershell
1..10 | Sort-Object -Property @{Expression={ Get-Random }}1..10 | Sort-Object -Property { Get-Random }
```

<!--本文国际来源：[Sorting Tricks (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/sorting-tricks-part-2)-->
