---
layout: post
date: 2017-06-05 00:00:00
title: "PowerShell 技能连载 - 强制刷新客户端时间"
description: PowerTip of the Day - Force Client Time Resync
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
如果您的客户端没有和您的域控制器正常地同步时间，请使用以下代码。这段代码需要管理员特权：

```powershell
w32tm.exe /resync /force
```

<!--more-->
本文国际来源：[Force Client Time Resync](http://community.idera.com/powershell/powertips/b/tips/posts/force-client-time-resync)
