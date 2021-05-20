---
layout: post
date: 2021-05-05 00:00:00
title: "PowerShell 技能连载 - 检测 Wi-Fi 信号强度（第 2 部分）"
description: PowerTip of the Day - Identifying Wi-Fi Signal Strength (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技能中，我们使用 `netsh.exe` 来确定 Wi-Fi 信号强度。由于 `netsh.exe` 返回的是原始格式的文本，因此需要大量的文本运算符技巧来提取实际的信号强度。通过调用结构化的 API 和对象成员直接访问信息始终是更优的方法。

坦白地说，没有内置的 PowerShell 方法可以以面向对象和结构化的方式访问 Wi-Fi 信息。但是，借助 PowerShell Gallery 中的免费 PowerShell 模块，您可以检索大量有用的 Wi-Fi 信息：

```powershell
Install-Module -Name Get-WLANs -Scope CurrentUser -Force
```

该模块基本上随附访问任何最新 Windows 操作系统中存在的内置 Windows "Managed Wi-Fi" 框架所需的 C# 代码。

安装该模块后，新命令 `Get-WLANs` 将返回有关所有可访问的 Wi-Fi 网络的面向对象的信息：

```powershell
PS> Get-WLANs

SSID       : internetcafe
BSSID      : 38:96:ED:0E:31:AD
RSSI       : -63
QUALITY    : 81
FREQ       : 5180
CHANNEL    : 36
PHY        : VHT
CAPABILITY : 0x1511
IESIZE     : 393

SSID       : guests
BSSID      : 3E:96:ED:0E:31:AD
RSSI       : -69
QUALITY    : 70
FREQ       : 5180
CHANNEL    : 36
PHY        : VHT
CAPABILITY : 0x1511
IESIZE     : 286
(...)
```

这也包括有关信号强度的信息（在 Quality 属性中）。

<!--本文国际来源：[Identifying Wi-Fi Signal Strength (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/identifying-wi-fi-signal-strength-part-2)-->

