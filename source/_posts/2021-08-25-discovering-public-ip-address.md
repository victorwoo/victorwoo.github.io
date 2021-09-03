---
layout: post
date: 2021-08-25 00:00:00
title: "PowerShell 技能连载 - 发现公共 IP 地址"
description: PowerTip of the Day - Discovering Public IP Address
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
使用 Web 服务，确定您的公共 IP 地址和有关您的 ISP 的信息几乎是举手之劳：

```powershell
PS> Invoke-RestMethod -Uri https://ipinfo.io


ip       : 84.165.49.158
hostname : p54a5319e.dip0.t-ipconnect.de
city     : Hannover
region   : Lower Saxony
country  : DE
loc      : 52.3705,9.7332
org      : AS3320 Deutsche Telekom AG
postal   : 30159
timezone : Europe/Berlin
readme   : https://ipinfo.io/missingauth
```

<!--本文国际来源：[Discovering Public IP Address](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/discovering-public-ip-address)-->

