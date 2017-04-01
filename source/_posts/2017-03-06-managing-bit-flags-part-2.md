layout: post
date: 2017-03-06 00:00:00
title: "PowerShell 技能连载 - 管理比特标志位（第二部分）"
description: PowerTip of the Day - Managing Bit Flags (Part 2)
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
在前一个技能中我们演示了如何使用 PowerShell 5 新的枚举特性来解析bite标志位，甚至可以独立地检测每个标志位。

如果您无法使用 PowerShell 5，在早期的 PowerShell 版本中，仍然可以使用这个技术只需要通过 C# 代码来定义枚举即可：

```powershell
# this is the decimal we want to decipher
$rawflags = 56823


# define an enum with the friendly names for the flags
# don't forget [Flags]
# IMPORTANT: you cannot change your type inside a PowerShell session!
# if you made changes to the enum, close PowerShell and open a new
# PowerShell!
$enum = '
using System;
[Flags]
public enum BitFlags
{
    None    = 0,
    Option1 = 1,
    Option2 = 2,
    Option3 = 4,
    Option4 = 8,
    Option5 = 16,
    Option6 = 32,
    Option7 = 64,
    Option8 = 128,
    Option9 = 256,
    Option10= 512,
    Option11= 1024,
    Option12= 2048,
    Option13= 4096,
    Option14= 8192,
    Option15= 16384,
    Option16= 32768,
    Option17= 65536
}
'
Add-Type -TypeDefinition $enum

# convert the decimal to the new enum
[BitFlags]$flags = $rawflags
$flags

# test individual flags
$flags.HasFlag([BitFlags]::Option1)
$flags.HasFlag([BitFlags]::Option2)
```

如您所见，从十进制数转换到新的枚举类型使用正常而且非常简单：

```powershell
PS C:\> [BitFlags]6625
Option1, Option6, Option7, Option8, Option9, Option12, Option13

PS C:\>
```

<!--more-->
本文国际来源：[Managing Bit Flags (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/managing-bit-flags-part-2)
