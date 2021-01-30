---
layout: post
date: 2021-01-27 00:00:00
title: "PowerShell 技能连载 - 识别位置和公共 IP"
description: PowerTip of the Day - Identifying Location and Public IP
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
下面的示例返回您的公共 IP 地址和位置：

```powershell
PS> Invoke-RestMethod -Uri 'ipinfo.io/json'


ip       : 84.183.236.178
hostname : p54b7ecb2.dip0.t-ipconnect.de
city     : Hannover
region   : Lower Saxony
country  : DE
loc      : 52.3705,9.7332
org      : AS3320 Deutsche Telekom AG
postal   : 30159
timezone : Europe/Berlin
readme   : https://ipinfo.io/missingauth
```

<!--本文国际来源：[Identifying Location and Public IP](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/identifying-location-and-public-ip)-->

