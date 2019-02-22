---
layout: post
date: 2019-02-15 00:00:00
title: "PowerShell 技能连载 - 转换 IEEE754 (Float)（第 2 部分）"
description: PowerTip of the Day - Converting IEEE754 (Float) (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
昨天我们研究了用 PowerShell 如何将传感器返回的 IEEE754 浮点值转换为实际值。这需要颠倒字节顺序并使用 `BitConverter` 类。

如果您收到了一个十六进制的 IEEE754 值，例如 0x3FA8FE3B，第一个任务就是将十六进制值分割为四个字节。实现这个目标简单得让人惊讶：将该十六进制值视为一个 IPv4 地址。这些地址内部也是使用四个字节。

以下是一个快速且简单的方法，能够将传感器的十六进制数值转换为一个有用的数值：

```powershell
$hexInput = 0x3FA8FE3B

$bytes = ([Net.IPAddress]$hexInput).GetAddressBytes()
$numericValue = [BitConverter]::ToSingle($bytes, 0)

"Sensor: $numericValue"
```

今日的知识点：

* 将数值转换为 `IPAddress` 对象来将数值分割为字节。这种方法也可以用来得到一个数字的最低有效位 (LSB) 或最高有效位 (MSB) 形式。

<!--本文国际来源：[Converting IEEE754 (Float) (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/converting-ieee754-float-part-2)-->
