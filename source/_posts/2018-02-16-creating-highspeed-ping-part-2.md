---
layout: post
date: 2018-02-16 00:00:00
title: "PowerShell 技能连载 - 创建快速的 Ping（第二部分）"
description: PowerTip of the Day - Creating Highspeed Ping (Part 2)
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
在前一个技能中我们演示了如何用 WMI 以指定的超时值 ping 计算机。WMI 还可以做更多的事：它可以迅速 ping 多台计算机，不过语法有一点另类。

以下是如何 ping 多台计算机：

```powershell
# ping the specified servers with a given timeout (milliseconds)
$TimeoutMillisec = 1000

Get-WmiObject -Class Win32_PingStatus -Filter "(Address='microsoft.com' or Address='r13-c14' or Address='google.com') and timeout=$TimeoutMillisec" | Select-Object -Property Address, StatusCode
```

<!--more-->
本文国际来源：[Creating Highspeed Ping (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/creating-highspeed-ping-part-2)
