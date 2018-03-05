---
layout: post
date: 2018-02-15 00:00:00
title: "PowerShell 技能连载 - 创建快速的 Ping（第一部分）"
description: PowerTip of the Day - Creating High-Speed Ping (Part 1)
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
Ping 是一个常见的任务。类似 `Test-Connection` 等 PowerShell cmdlet 可以进行 Ping 操作，但没有超时限制，所以当您尝试 ping 一台离线的主机时，可能要比较长时间才能得到结果。

WMI 支持带超时的 ping 操作。以下是使用方法：

```powershell
$ComputerName = 'microsoft.com'
$TimeoutMillisec = 1000

Get-WmiObject -Class Win32_PingStatus -Filter "Address='$ComputerName' and timeout=$TimeoutMillisec" | Select-Object -Property Address, StatusCode
```

状态码 0 代表成功，其它代码代表失败。

<!--more-->
本文国际来源：[Creating High-Speed Ping (Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/creating-high-speed-ping-part-1)
