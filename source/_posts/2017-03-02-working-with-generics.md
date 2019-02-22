---
layout: post
date: 2017-03-02 00:00:00
title: "PowerShell 技能连载 - 使用泛型"
description: PowerTip of the Day - Working With Generics
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
泛型可以作为实际类型的占位符，您可能会好奇为什么它会有意思。

有许多不同的数据类型没有 NULL 值。例如 Integer 和 Boolean 型，没有办法指出一个值是非法的还是未设置。您可以通过将一个 0（或者 -1）指定为某个 integer 变量的 "undefined" 值。但如果所有的数字都是合法的值呢？对于 Boolean，情况也是一样：虽然您可以定义 `$false` 值为 "undefined" 值，但许多情况下的确需要三种值：`$true`、`$flase` 和 `undefined`。

泛型是解决的办法，您可以使用 `Nullable` 类型根据任何合法的类型来创建自己的可空值类型。

```powershell
[Nullable[int]]$number =  $null
[Nullable[bool]]$flag =  $null

$number
$flag
```

用常规数据类型来做数据转换：

```powershell
PS C:\> [int]$null
0

PS C:\> [bool]$null
False

PS C:\>
```

<!--本文国际来源：[Working With Generics](http://community.idera.com/powershell/powertips/b/tips/posts/working-with-generics)-->
