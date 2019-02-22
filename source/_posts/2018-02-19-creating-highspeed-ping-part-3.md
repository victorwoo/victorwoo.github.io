---
layout: post
date: 2018-02-19 00:00:00
title: "PowerShell 技能连载 - 创建快速的 Ping（第三部分）"
description: PowerTip of the Day - Creating Highspeed Ping (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们演示了如何用 WMI 快速 ping 多台计算机，它的语法比较另类。那么让我们重写代码，使得指定要 ping 的计算机列表变得更容易：

```powershell
# ping the specified servers with a given timeout (milliseconds)
$ComputerName = 'google.de','microsoft.com','r13-c00'
$TimeoutMillisec = 1000
    
# convert list of computers into a WMI query string
$query = $ComputerName -join "' or Address='"
    
Get-WmiObject -Class Win32_PingStatus -Filter "(Address='$query') and timeout=$TimeoutMillisec" | Select-Object -Property Address, StatusCode
```

现在要 ping 更大量的计算机变得更容易：只要将它们加入 `$ComputerName` 字符串数组。假如有一个文本文件，每行是一个计算机名，您也可以用 `Get-Content` 来写入 `$ComputerName` 变量。

<!--本文国际来源：[Creating Highspeed Ping (Part 3)](http://community.idera.com/powershell/powertips/b/tips/posts/creating-highspeed-ping-part-3)-->
