---
layout: post
date: 2018-06-15 00:00:00
title: "PowerShell 技能连载 - 从本地时间以 ISO 格式创建 UTC 时间"
description: PowerTip of the Day - Create Universal Time from Local Time in ISO Format
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
如果您的工作是跨国跨时区的，您可能会需要使用 UTC 时间来代替本地时间。要确保时间格式是语言中性的，我们推荐使用 ISO 格式。以下是使用方法：

```powershell
$date = Get-Date
$date.ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss')
```

<!--more-->
本文国际来源：[Create Universal Time from Local Time in ISO Format](http://community.idera.com/powershell/powertips/b/tips/posts/create-universal-time-from-local-time-in-iso-format)
