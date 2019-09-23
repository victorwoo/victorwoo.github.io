---
layout: post
date: 2019-09-19 00:00:00
title: "PowerShell 技能连载 - 查找公网 IP 地址"
description: PowerTip of the Day - Finding Public IP Address
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
这是一个单行程序，检索您当前的公共IP地址：

```
PS> Invoke-RestMethod -Uri http://ipinfo.io


ip       : 87.153.224.209
hostname : p5799e0d1.dip0.t-ipconnect.de
city     : Hannover
region   : Lower Saxony
country  : DE
loc      : 52.3705,9.7332
org      : AS3320 Deutsche Telekom AG
postal   : 30159
timezone : Europe/Berlin
readme   : https://ipinfo.io/missingauth
```

<!--本文国际来源：[Finding Public IP Address](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/finding-public-ip-address-1)-->

