layout: post
date: 2016-10-03 00:00:00
title: "PowerShell 技能连载 - 查找由 DHCP 分配的 IP 地址"
description: PowerTip of the Day - Finding IP Address Assigned by DHCP
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
从 Windows 8 和 Server 2012 起，随着操作系统一起分发了一些扩展的 PowerShell 模块，用于管理服务器和客户端，例如 `Get-NetIPAddress` 等 cmdlet。

如果您想获得一个所有由 DHCP 分配的 IP 地址列表，可以试试以下方法：

```powershell
#requires -Version 3.0 -Modules NetTCPIP

Get-NetIPAddress | 
  Where-Object PrefixOrigin -eq dhcp | 
  Select-Object -ExpandProperty IPAddress
```

<!--more-->
本文国际来源：[Finding IP Address Assigned by DHCP](http://community.idera.com/powershell/powertips/b/tips/posts/finding-ip-address-assigned-by-dhcp)
