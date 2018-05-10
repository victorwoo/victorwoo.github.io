---
layout: post
date: 2018-05-07 00:00:00
title: "PowerShell 技能连载 - WMI 快速入门（第 3 部分）"
description: PowerTip of the Day - WMI Quick Primer (Part 3)
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
在前一个技能中我们解释了为什么 `Get-CimInstance` 比旧的 `Get-WmiObject` cmdlet 有优势。

这是另一个例子，演示了为什么 `Get-CimInstance` 可能会比 `Get-WmiObject` 快得多。

当您需要从远程主机查询多个 WMI 类，例如您需要创建一个库存报告，每次运行 cmdlet 时 `Get-WmiObject` 需要连接和断开连接。然而 `Get-CimInstance` 可以复用已有的 session。

以下是一个演示如何在两个查询中复用同一个 session 的例子：

```powershell
# create the session
$options = New-CimSessionOption -Protocol Wsman
$session = New-CimSession -ComputerName sr0710 -SessionOption $options

# reuse the session for as many queries as you like
$sh = Get-CimInstance -ClassName Win32_Share -CimSession $session -Filter 'Name="Admin$"'
$se = Get-CimInstance -ClassName Win32_Service -CimSession $session

# remove the session at the end
Remove-CimSession -CimSession $session
```

当您需要连接到不支持 WSMan 的旧的计算机，只需要将以上代码的协议改为 DCOM 即可：将 `Wsman` 替换为 `Dcom`。

<!--more-->
本文国际来源：[WMI Quick Primer (Part 3)](http://community.idera.com/powershell/powertips/b/tips/posts/wmi-quick-primer-part-3)
