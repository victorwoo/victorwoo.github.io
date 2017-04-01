layout: post
title: "PowerShell 技能连载 - 查找无线网卡"
date: 2014-03-17 00:00:00
description: PowerTip of the Day - Finding Wireless Network Adapters
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
有很多方法可以查找网卡，但似乎没有办法识别活动的无线网卡。

您网卡的所有信息都可以在注册表中找到，以下是一个单行的代码，可以提供您想要的信息：

![](/img/2014-03-17-finding-wireless-network-adapters-001.png)

有趣的部分是 `MediaSubType` 值。无线网卡的 MediaSubType 值总是 2。

所以这行代码只返回无线网卡：

![](/img/2014-03-17-finding-wireless-network-adapters-002.png)

<!--more-->
本文国际来源：[Finding Wireless Network Adapters](http://community.idera.com/powershell/powertips/b/tips/posts/finding-wireless-network-adapters)
