---
layout: post
date: 2019-03-07 00:00:00
title: "PowerShell 技能连载 - 求比特位反码"
description: PowerTip of the Day - Inverting Bits
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有些时候需要求一个数字的比特位反码。最常见的情况是属于某种自定义的算法或计算校验。这引出了一个通用的问题：最简单的实现方法是什么？

“求比特位反码”操作可以通过 `-bnot` 操作符实现，类似这样：

```powershell
$number = 76
[Convert]::ToString($number,2)

$newnumber = -bnot $number
[Convert]::ToString($newnumber,2)
```

不过，结果会显示一个警告：

    1001100
    11111111111111111111111110110011

这个操作符总是针对 64 位的有符号数。一个更好的方法是使用 `-bxor` 操作符，并且根据需要颠倒的数据类型提供对应的比特位掩码。对于一个字节，比特位掩码是 `0xFF`，对于 `Int32`，比特位掩码是 `0xFFFFFFFF`。以下是一个求某个字节的比特位反码的示例。我们将一个字符串结果填充至 8 个字符，来确保前导零可见：

```powershell
$number = 76
[Convert]::ToString([byte]$number,2).PadLeft(8, '0')

$newnumber = $number -bxor 0xFF
[Convert]::ToString($newnumber,2).PadLeft(8, '0')
```

结果是正确的：

    01001100
    10110011

今日知识点：

* PowerShell 包含了许多二进制操作符，它们都以 `-b...` 开头。
* 要求比特位反码，您可以使用 `-bnot`。如果只要反转某几位，请使用 `-bxor` 和自定义比特掩码。

<!--本文国际来源：[Inverting Bits](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/inverting-bits)-->
