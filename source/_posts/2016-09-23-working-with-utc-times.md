---
layout: post
date: 2016-09-23 00:00:00
title: "PowerShell 技能连载 - 使用 UTC 时间"
description: PowerTip of the Day - Working with UTC Times
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在跨语言环境中，您可能希望有一种方法能将日期和时间“通用化”，例如在写日志的时候。和使用当地时间比起来，用 PowerShell 能够很方便地将 `DateTime` 对象转化为协调世界时 (UTC)：

```powershell
(Get-Date).ToUniversalTime()
```

<!--本文国际来源：[Working with UTC Times](http://community.idera.com/powershell/powertips/b/tips/posts/working-with-utc-times)-->
