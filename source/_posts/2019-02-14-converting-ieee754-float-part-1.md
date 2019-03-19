---
layout: post
date: 2019-02-14 00:00:00
title: "PowerShell 技能连载 - 转换 IEEE754 (Float)（第 1 部分）"
description: PowerTip of the Day - Converting IEEE754 (Float) (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 是非常多功能的，并且现在常常用于 IoT 和传感器。一些 IEEE754 浮点格式往往是一系列四字节的十六进制数。

我们假设一个传感器以 IEEE754 格式返回一个十六进制的数值  3FA8FE3B。那么要如何获取真实值呢？

技术上，您需要颠倒字节顺序，然后用 `BitConverter` 来创建一个 "Single" 值。

以 3FA8FE3B 为例，将它逐对分割，颠倒顺序，然后转换为一个数字：

```powershell
$bytes = 0x3B, 0xFE, 0xA8, 0x3F
[BitConverter]::ToSingle($bytes, 0)
```

实际结果是，十六进制数值 0x3FA8FE3B 返回了传感器值 1.320258。今天，我们研究 `BitConverter` 类，这个类提供了多个将字节数组转换为数值的方法。明天，我们将查看另一部分：将十六进制文本数值成对分割并颠倒顺序。

今日的知识点：

* 使用 `[BitConverter]` 来将原始字节数组转换为其它数字格式。这个类有大量方法：

```powershell
PS> [BitConverter] | Get-Member -Static | Select-Object -ExpandProperty Name

DoubleToInt64Bits
Equals
GetBytes
Int64BitsToDouble
IsLittleEndian
ReferenceEquals
ToBoolean
ToChar
ToDouble
ToInt16
ToInt32
ToInt64
ToSingle
ToString
ToUInt16
ToUInt32
ToUInt64
```

要查看其中某个方法的语法，请键入它们的名称，不包括圆括号：

```powershell
PS> [BitConverter]::ToUInt32

OverloadDefinitions
-------------------
static uint32 ToUInt32(byte[] value, int startIndex)
```

<!--本文国际来源：[Converting IEEE754 (Float) (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/converting-ieee754-float-part-1)-->
