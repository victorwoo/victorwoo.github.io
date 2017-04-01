layout: post
date: 2014-11-13 12:00:00
title: "PowerShell 技能连载 - 使用 IPv4 来 Ping"
description: 'PowerTip of the Day - Pinging via IPv4 '
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
_适用于 PowerShell 所有版本_

您可以像其它命令一样在 PowerShell 脚本中使用 ping.exe。向 ping 命令加入“`-4`”参数之后，您可以强制 ping 命令使用 IPv4 协议（也可以用“`-6`”参数强制使用 IPv6）。

    PS> ping localhost -4

<!--more-->
本文国际来源：[Pinging via IPv4 ](http://community.idera.com/powershell/powertips/b/tips/posts/pinging-via-ipv4)
