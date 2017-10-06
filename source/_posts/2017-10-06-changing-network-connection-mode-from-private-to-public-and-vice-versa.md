---
layout: post
date: 2017-10-06 00:00:00
title: "PowerShell 技能连载 - 将网络连接模式从私有网络切到公有网络（反之亦然）"
description: PowerTip of the Day - Changing Network Connection Mode from Private to Public (and vice versa)
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
Starting with Windows Server 2012 R2 and Windows 8.1, PowerShell ships with many useful cmdlets for client and server configuration. This comes handy as some settings can no longer be controlled via UI.
从 Windows Server 2012 R2 和 Windows 8.1 开始，随着 PowerShell 发布了许多有用的客户端和服务器配置 cmdlet。这些 cmdlet 十分趁手，因为一些设置可以不再通过 UI 来控制。

例如，要改变网络的类型，只需要以管理员身份运行以下代码：

```powershell
PS> Get-NetConnectionProfile


Name             : internet-cafe
InterfaceAlias   : WiFi
InterfaceIndex   : 13
NetworkCategory  : Private
IPv4Connectivity : Internet
IPv6Connectivity : Internet




PS> Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Public -WhatIf
What if:
```

<!--more-->
本文国际来源：[Changing Network Connection Mode from Private to Public (and vice versa)](http://community.idera.com/powershell/powertips/b/tips/posts/changing-network-connection-mode-from-private-to-public-and-vice-versa)
