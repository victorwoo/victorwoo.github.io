---
layout: post
date: 2022-06-01 00:00:00
title: "PowerShell 技能连载 - 读取 Windows 10 产品序列号"
description: PowerTip of the Day - Reading Windows 10 Product Key
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有很多脚本可以通过转换一系列二进制值来读取注册表的原始 Windows 10 产品序列号。

不幸的是，这些脚本中找到的大多数算法都是弃用的，并且计算出的产品密钥是错误的。如果您计划重新安装操作系统，则有可能在删除了原来的系统后才发现。

这行代码可能是一种更好，更简单的方法：

```powershell
PS> (Get-CimInstance -ClassName SoftwareLicensingService).OA3xOriginalProductKey  
```

如果它返回 "nothing"，则机器中没有安装产品序列号。否则，它将原样返回。

<!--本文国际来源：[Reading Windows 10 Product Key](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/reading-windows-10-product-key)-->

