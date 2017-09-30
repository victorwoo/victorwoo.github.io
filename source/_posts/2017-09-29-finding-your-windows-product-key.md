---
layout: post
date: 2017-09-29 00:00:00
title: "PowerShell 技能连载 - 查找 Windows 的产品密钥"
description: PowerTip of the Day - Finding Your Windows Product Key
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
当您需要从备份中还原电脑状态时，首先要知道您的 Windows 产品密钥。以下是一个简单的单行命令，可以获得产品密钥信息：

```powershell
(Get-WmiObject -Class SoftwareLicensingService).OA3xOriginalProductKey
```

<!--more-->
本文国际来源：[Finding Your Windows Product Key](http://community.idera.com/powershell/powertips/b/tips/posts/finding-your-windows-product-key)
