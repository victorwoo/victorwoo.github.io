layout: post
date: 2017-03-07 16:00:00
title: "PowerShell 技能连载 - 管理比特标志位（第四部分）"
description: PowerTip of the Day - Managing Bit Flags (Part 4)
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
在 PowerShell 5 中，对枚举的新支持特性使得处理比特位比您在前面的 PowerShell 技能中看到的简单得多。现在设置或清除比特位不再需要冗长的逻辑操作符。

我们先定义一个枚举类型，这样更好管理十进制数：

```powershell
#requires -Version 5

[Flags()]
enum GardenPartyItems
{
    Chair = 0
    Table = 1
    Barbecue = 2
    Fridge = 4
    Candle = 8
    Knife = 16
}

$decimal = 11
[GardenPartyItems]$flags = $decimal
$flags
```

现在，十进制数的比特位可以很容易地转化为 GardenPartyItem 的列表：

```powershell
PS C:\>  [GardenPartyItems]11
Table, Barbecue, Candle

PS C:\>
```

**注意**：将十进制数转换为枚举型时，请确保枚举型中定义了所有的比特。如果十进制数太大，包含枚举型之外的比特时，转换会失败。

要增加一个新的标志位，请试试以下的代码：

```powershell
PS C:\> $flags
Table, Barbecue, Candle

PS C:\> $flags += [GardenPartyItems]::Knife

PS C:\> $flags
Table, Barbecue, Candle, Knife

PS C:\>
```

要移除一个标志位，请试试以下代码：

```powershell
PS C:\> $flags
Table, Barbecue, Candle, Knife

PS C:\> $flags -= [GardenPartyItems]::Candle

PS C:\> $flags
Table, Barbecue, Knife

PS C:\>
```

然而，实际上并没有看起来这么简单。当移除一个已有的标志位，没有问题。但移除一个没有置位的标志位，会把比特值搞乱：

```powershell
PS C:\> $flags
Table, Barbecue, Candle

PS C:\> $flags -= [GardenPartyItems]::Candle

PS C:\> $flags
Table, Barbecue

PS C:\> $flags -= [GardenPartyItems]::Candle

PS C:\> $flags
-5

PS C:\>
```

所以 PowerShell 在自动处理二进制算法方面明显还不够智能。要安全地使用该功能，您还是要用二进制操作符。要移除标志位，请使用 `-band` 和 `-bnot`：

```powershell
PS C:\> $flags
Table, Barbecue, Candle

PS C:\> $flags = $flags -band -bnot [GardenPartyItems]::Candle

PS C:\> $flags
Table, Barbecue

PS C:\> $flags = $flags -band -bnot [GardenPartyItems]::Candle

PS C:\> $flags
Table, Barbecue

PS C:\>
```

要设置标志位，请使用 `-bor`：

```powershell
PS C:\> $flags
Table, Barbecue, Candle

PS C:\> $flags = $flags -bor [GardenPartyItems]::Knife

PS C:\> $flags
Table, Barbecue, Candle, Knife

PS C:\> $flags = $flags -bor [GardenPartyItems]::Knife

PS C:\> $flags
Table, Barbecue, Candle, Knife

PS C:\>
```

在所有这些操作中，实际上是在操作一个十进制数：

```powershell
PS C:\> [Int]$flags
19
```

相当棒，对吧？

<!--more-->
本文国际来源：[Managing Bit Flags (Part 4)](http://community.idera.com/powershell/powertips/b/tips/posts/managing-bit-flags-part-4)
