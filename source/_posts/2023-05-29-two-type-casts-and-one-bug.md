---
layout: post
date: 2023-05-29 00:00:38
title: "PowerShell 技能连载 - 两种类型转换（和一个 bug）"
description: PowerTip of the Day - Two Type Casts (and one bug)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
为了明确将一个数据类型转换为另一个数据类型，PowerShell提供了两种方法：

```powershell
PS> [int]5.6
6

PS> 5.6 -as [int]
6
```

虽然这两种方法在大多数情况下都会产生相同的结果，但存在细微差异：

* 当你在数据之前添加目标类型时，PowerShell 使用美国文化，并在转换失败时引发异常。
* 当你使用 "`-as`" 运算符时，PowerShell 使用你的本地文化，在转换失败时不引发异常。

当你在非英语系统上进行字符串到日期时间的转换时，不同的文化变得重要：

```powershell
PS> [datetime]'1.5.23'

Donnerstag, 5. Januar 2023 00:00:00

PS> '1.5.23' -as [datetime]

Montag, 1. Mai 2023 00:00:00
```

最后，这两种方法都存在一个奇怪的错误，即使输入的字符串明显损坏，类型转换仍然有效：

PS> [Type] 'int]whatever'

IsPublic IsSerial Name                                     BaseType
-------- -------- ----                                     --------
True     True     Int32                                    System.ValueType

PS> 'int]whatever' -as [Type]

IsPublic IsSerial Name                                     BaseType
-------- -------- ----                                     --------
True     True     Int32                                    System.ValueType

不过，不要利用这个错误，因为在 PowerShell 7 中很快会修复它。
<!--本文国际来源：[Two Type Casts (and one bug)](https://blog.idera.com/database-tools/powershell/powertips/two-type-casts-and-one-bug/)-->

