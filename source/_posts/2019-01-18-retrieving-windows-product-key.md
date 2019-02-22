---
layout: post
date: 2019-01-18 00:00:00
title: "PowerShell 技能连载 - Retrieving Windows Product Key"
description: PowerTip of the Day - Retrieving Windows Product Key
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
以下是获取当前 Windows 产品序列号的单行代码：

```powershell
(Get-WmiObject -Class "SoftwareLicensingService").OA3xOriginalProductKey
```

<!--本文国际来源：[Retrieving Windows Product Key](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/retrieving-windows-product-key)-->
