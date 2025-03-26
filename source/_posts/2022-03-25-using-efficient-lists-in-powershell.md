---
layout: post
date: 2022-03-25 00:00:00
title: "PowerShell 技能连载 - 在 PowerShell 使用高效的列表"
description: PowerTip of the Day - Using Efficient Lists in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
默认情况下，当您定义列表、命令返回多个结果或需要在变量中存储多个内容时，PowerShell 使用简单的“对象数组”。

默认对象数组是可以的，但是一旦你创建了它们，它们的容量就不能增长。如果仍然尝试使用 "`+=`" 运算符，脚本可能会突然花费很长时间或永远不会完成：

```powershell
# default array
$array = @()

1..100000 | ForEach-Object {
    # += is actually creating a new array each time with one more entry
    # this is very slow
    $array += "adding $_"
}

$array.count
```

那是因为 "`+=`" 其实是个谎言，PowerShell 实际上需要创建一个新的更大的数组并将内容从旧数组复制到新数组。如果只是几个元素，那么还好但是如果要添加的元素较多，就会导致指数级延迟。

最常见的解决方法是使用可以动态增长的 `System.Collections.ArrayList` 类型。您可以简单地将默认数组强制转换为这种类型。

这是一种常用的方法，速度更快：

```powershell
# use a dynamically extensible array
$array = [System.Collections.ArrayList]@()

1..100000 | ForEach-Object {
    # use the Add() method instead of "+="
    # discard the return value provided by Add()
    $null = $array.Add("adding $_")
}

$array.count
```

请注意它如何使用 `Add()` 方法而不是 "`+=`" 运算符。

不过，`System.Collections.ArrayList` 有两个缺点：它的 `Add()` 方法返回添加新元素的位置，并且由于此信息没有意义，因此需要手动丢弃它，即将其分配给 `$null`。并且 `ArrayLists` 不是特定于类型的。它们可以存储任何数据类型，这使得它们虽然灵活但效率不高。

泛型列表要好得多，使用它们只是使用不同类型的问题。一方面，泛型列表可以限制为给定类型，因此它们可以以最有效的方式存储数据并提供类型安全。以下是字符串列表的示例：

```powershell
# use a typed list for more efficiency
$array = [System.Collections.Generic.List[string]]@()

1..100000 | ForEach-Object {
    # typed lists support Add() as well but there is no
    # need to discard a return value
    $array.Add("adding $_")
}

$array.count
```

如果您需要一个整形列表，只需替换泛型列表类型名称中的类型：

```powershell
[System.Collections.Generic.List[int]]
```

强类型限制只是“可以”，而不是“必须”。如果您希望泛型列表与 `ArrayList` 一样灵活并接受任何类型，请使用 "`object`" 类型：

```powershell
[System.Collections.Generic.List[object]]
```

<!--本文国际来源：[Using Efficient Lists in PowerShell](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-efficient-lists-in-powershell)-->

