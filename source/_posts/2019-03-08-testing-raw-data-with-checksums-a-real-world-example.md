---
layout: post
date: 2019-03-08 00:00:00
title: "PowerShell 技能连载 - 通过校验位测试原始数据——实际案例"
description: "PowerTip of the Day - Testing Raw Data with Checksums – A Real-World Example"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
随着 PowerShell 进入物联网世界，有些时候需要处理二进制的传感器数据和古老的校验模型来确保数据的完整性。

这是一个如何用 PowerShell 处理传感器数据并且校验其正确性的真实案例。这里介绍的案例仅适用于特定的用例，但是这里介绍的技术原理对类似的传感器依然有效。

在这个例子中，PowerShell 收到一系列十六进制数据 (`$data`)。校验码是最后一个字节 (`3A`)。它的定义是数据报文中所有字节的和。在这个总和中用的是最低有效字节来表示校验位，而且要求比特为反码。听起来很奇怪但是有道理。通过这种方式计算出来的校验和永远只有一个字节。

以下是 PowerShell 处理这些需求的方法，将校验位和计算出来的校验位对比，就可以测试数据的完整性：

```powershell
$data = '00030028401D2E8D4022C0EE4022C0E64022C0E6418B4ACD419FE7B641A05F0E41A060D041A061C23F0A7CDA3A'

# checksum is last byte
$checksum = [Convert]::ToByte($data.Substring($data.Length-2,2), 16)

# remove checksum from data
$data = $data.Substring(0, $data.Length -2)

# sum up all bytes
$sum = $data -split '(?<=\G.{2})(?=.)' |
  Foreach-Object {$c = 0}{$c+=[Convert]::ToByte($_,16)}{ $c }

# get the least significant byte
$lsb = ([Net.IPAddress]$sum).GetAddressBytes()[0]

# invert bits
$checksumReal = $lsb -bxor 0xFF

# compare
if ($checksum -ne $checksumReal)
{
  throw "Checksum does not match"
}
else
{
  Write-Warning "Checksum ok"
}
```

今日知识点：

* 用 `[Convert]::ToByte($number, 16)` 将十六进制字符串转换为数字。
* 通过正则表达式，可以很容易地将一个字符流（例如十六进制对）转换为一对一对字符的列表，这样可以计算总和。
* 通过将一个数字转换为 `IPAddress`，可以方便地操作不同的字节顺序 (LSB, MSB)。
* 用 `-bxor` 求比特位反码。

<!--本文国际来源：[Testing Raw Data with Checksums – A Real-World Example](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/testing-raw-data-with-checksums-a-real-world-example)-->
