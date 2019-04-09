---
layout: post
date: 2019-04-08 00:00:00
title: "PowerShell 技能连载 - 优先使用 WLAN 连接"
description: PowerTip of the Day - Preferring WLAN Connections
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您同时连接到 LAN 和 WLAN，并且希望指定一个优先的连接，那么您可以调整网络跃点。网络跃点值越小，网卡的优先级越高。

要列出当前首选项，请使用 `Get-NetIPInterface`。例如要将所有 WLAN 网卡的跃点值设成 10，请使用这行代码：

```powershell
Get-NetIPInterface -InterfaceAlias WLAN |
  Set-NetIPInterface -InterfaceMetric 10
```

改变网络跃点值需要管理员权限。相关 cmdlet 在 Windows 10 和 Windows Server 2016/2019 中可用。

<!--本文国际来源：[Preferring WLAN Connections](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/preferring-wlan-connections)-->

