---
layout: post
date: 2019-03-06 00:00:00
title: "PowerShell 技能连载 - 计算最高和最低有效字节"
description: PowerTip of the Day - Calculating Most and Least Significant Byte
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
数字在内部是以字节的形式存储的。例如一个 `Int32` 数值使用 4 个字节。有些时候需要将数字分割为字节，例如要以 TODO least significiant 字节顺序计算校验和。

我们创建了一个快速的全览，您也可以将它当作一个基本的数字处理教程。它演示了数字如何对应到字节，并且如何计算最低有效字节 (LSB) 和最高有效字节 (MSB)，以及其它：

```powershell
function Show-Header([Parameter(ValueFromRemainingArguments)][string]$Text)
{
  $Width=80
  $padLeft = [int]($width / 2) + ($text.Length / 2)
  ''
  $text.PadLeft($padLeft, "=").PadRight($Width, "=")
  ''
}


Show-Header Starting with this number:
$number = 26443007
$number

Show-Header Display the bits for this number:
$bits = [Convert]::ToString($number,2)
$bits

Show-Header Add missing leading zeroes:
# pad the string to its full bit range (32 bits)
$bitsAligned = $bits.PadLeft(32, '0')
$bitsAligned

Show-Header Display the four byte groups
$bitsAligned -split '(?<=\G.{8})(?=.)' -join '-'

Show-Header Get the bytes by conversion to IPAddress object:
$bytes = ([Net.IPAddress]$number).GetAddressBytes()
$bytes

Show-Header Display the bits for the IPAddress bytes:
$bitbytes = $bytes | ForEach-Object { [Convert]::ToString($_, 2).PadLeft(8,'0')}
$bitbytes -join '-'

Show-Header Show the Least Significant Byte LSB:
$bytes[0]

Show-Header Show LSB by turning the 8 bits to the right into a number to verify:
$bits = [Convert]::ToString($number, 2)
# take least significant bits
[Convert]::toByte($bits.Substring($bits.Length-8),2)

Show-Header Show the Most Significant Byte MSB:
$bytes[3]
```

如您所见，有许多方法可以实现。一个特别聪明的办法是将数字转换为一个 `IPAddress`。`IPAddress` 对象有一个好用的 `GetAddressBytes()` 方法，可以将数字轻松地分割为字节。

结果看起来类似这样：

    ===========================Starting with this number:===========================

    26443007

    =======================Display the bits for this number:========================

    1100100110111110011111111

    ===========================Add missing leading Zeroes:==========================

    00000001100100110111110011111111

    ==========================Display the four byte groups==========================

    00000001-10010011-01111100-11111111

    ================Get the bytes by conversion to IPAddress object:================

    255
    124
    147
    1

    ===================Display the bits for the IPAddress bytes:====================

    11111111-01111100-10010011-00000001

    ======================Show the Least Significant Byte LSB:======================

    255

    ======Show LSB by turning the 8 bits to the right into a number to verify:======

    255

    =======================Show the Most Significant Byte MSB:======================

    1

<!--本文国际来源：[Calculating Most and Least Significant Byte](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/calculating-most-and-least-significant-byte)-->
