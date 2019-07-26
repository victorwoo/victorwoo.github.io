---
layout: post
date: 2017-11-22 00:00:00
title: "PowerShell 技能连载 - 理解 PowerShell 中 .NET 类型名称的变体"
description: PowerTip of the Day - Understanding .NET Type Name Variants in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 使用 .NET 类型名，例如将值转换为指定的类型。脚本中常常可以使用各种格式来定义 .NET 类型。以下是它们各自的用意和含义：

```powershell
# short name for "Integer" data type
[int]12.4
# official .NET type name
[system.int32]12.4
# here is how you get there
[int].FullName
# with official names, the namespace "System" is always optional
[int32]12.4
```

简单来说，PowerShell 维护着它自己的“类型加速器”：.NET 类型的别名。查看任意类型的 `FullName` 属性，可以获得完整正式的 .NET 类型名。类型名前面的 "System." 是可以省略的。

<!--本文国际来源：[Understanding .NET Type Name Variants in PowerShell](http://community.idera.com/powershell/powertips/b/tips/posts/understanding-net-type-name-variants-in-powershell)-->
