---
layout: post
date: 2018-06-05 00:00:00
title: "PowerShell 技能连载 - 配置网络适配器"
description: PowerTip of the Day - Configuring Network Adapter
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
以下是一个简单的例子，演示如何向网络适配器分配 IP 地址、网关，和 DNS 服务器。这段脚本列出所有活动的网络适配器。当您选择一项并点击确认，脚本将把硬编码的地址赋给网络适配器。

请注意一下脚本只是模拟改变网络配置。如果您希望真的改变网络设置，请移除 `-WhatIf` 参数：

```powershell
$NewIP = '192.168.2.12'
$NewGateway = '192.168.2.2'
$NewDNS = '8.8.8.8'
$Prefix = 24

$adapter = Get-NetAdapter |
Where-Object Status -eq 'Up' |
Out-GridView -Title 'Select Adapter to Configure' -OutputMode Single
$index = $adapter.InterfaceIndex

New-NetIPAddress -InterfaceIndex $index -IPAddress $NewIP -DefaultGateway $NewGateway -PrefixLength $Prefix -AddressFamily IPv4 -WhatIf
Set-DNSClientServerAddress –InterfaceIndex $index –ServerAddresses $NewDNS -whatIf
```

<!--more-->
本文国际来源：[Configuring Network Adapter](http://community.idera.com/powershell/powertips/b/tips/posts/configuring-network-adapter)
