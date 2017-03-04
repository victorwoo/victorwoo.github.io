layout: post
date: 2017-03-02 16:00:00
title: "PowerShell 技能连载 - 管理比特标志位（第一部分）"
description: PowerTip of the Day - Managing Bit Flags (Part 1)
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
有时候您会需要处理比特标志位值。一个数字中的每个比特代表一个特定的设置，并且您的代码可能需要决定一个标志位是否置位，而不能影响别的比特。

这常常需要一系列位操作。然而在 PowerShell 5 中，有一个简单得多的办法——标志位枚举。

假设有一个值 56823，并且希望知道哪个比特是置位的。您需要将该数字转换成可视化的比特：

```powershell
    PS C:\> [Convert]::ToString(56823, 2)
    1101110111110111
```

如果您了解每个比特的意义，那么一个更强大的方法是定义一个枚举：

```powershell
#requires -Version 5

[flags()]
enum CustomBitFlags
{
    None    = 0
    Option1 = 1
    Option2 = 2
    Option3 = 4
    Option4 = 8
    Option5 = 16
    Option6 = 32
    Option7 = 64
    Option8 = 128
    Option9 = 256
    Option10= 512
    Option11= 1024
    Option12= 2048
    Option13= 4096
    Option14= 8192
    Option15= 16384
    Option16= 32768
    Option17= 65536
}
```

对每个比特提供一个友好的名字，并且记得添加属性 `[Flags]`（这将允许设置多个值）。

现在要解析这个十进制值非常简单——只需要将它转换成新定义的枚举类型：

```powershell
$rawflags = 56823
[CustomBitFlags]$flags = $rawflags
```

这时得到的结果：

```powershell
    PS C:\> $flags
    Option1, Option2, Option3, Option5, Option6, Option7, Option8, Option9, Option11, Option12, Option13, Option15, Option16
```

如果您只希望检测某个标志位是否置位，请使用 `HasFlag()` 方法：

```powershell
PS C:\> $flags.HasFlag([CustomBitFlags]::Option1)

True

PS C:\> $flags.HasFlag([CustomBitFlags]::Option4)

False
```

<!--more-->
本文国际来源：[Managing Bit Flags (Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/managing-bit-flags-part-1)
