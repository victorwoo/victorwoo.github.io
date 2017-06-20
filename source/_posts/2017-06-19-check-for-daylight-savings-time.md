---
layout: post
date: 2017-06-19 00:00:00
title: "PowerShell 技能连载 - 检查夏时制"
description: PowerTip of the Day - Check for Daylight Savings Time
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
以下用 PowerShell 来查看是否使用了夏时制的方法——进行 GMT 计算时可能需要的细节：

```powershell
(Get-Date).IsDaylightSavingTime()
```

<!--more-->
本文国际来源：[Check for Daylight Savings Time](http://community.idera.com/powershell/powertips/b/tips/posts/check-for-daylight-savings-time)
