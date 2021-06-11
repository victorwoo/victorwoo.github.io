---
layout: post
date: 2021-06-10 00:00:00
title: "PowerShell 技能连载 - 原版 Windows 10 产品密钥"
description: PowerTip of the Day - Original Windows 10 Product Key
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有大量 PowerShell 脚本到处流传，它们生成可以解码原始的 Windows 10 产品密钥。大多数这些脚本使用过时的算法，这些算法不再适用于 Windows 10。

这是检索原始 Windows 10 产品密钥的更简单的方法：

```powershell
Get-CimInstance -ClassName SoftwareLicensingService |
  Select-Object -ExpandProperty OA3xOriginalProductKey
```

如果该命令不产生任何返回信息，则操作系统安装中没有存储单独的产品密钥。

<!--本文国际来源：[Original Windows 10 Product Key](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/original-windows-10-product-key)-->

