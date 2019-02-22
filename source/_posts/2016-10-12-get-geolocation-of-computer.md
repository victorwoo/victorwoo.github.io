---
layout: post
date: 2016-10-12 00:00:00
title: "PowerShell 技能连载 - 获取计算机的地理位置"
description: PowerTip of the Day - Get GeoLocation of Computer
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
这是获取地理位置信息的另一个免费源，它能够获取您当前的公网 IP 和位置信息：

```powershell
#requires -Version 3.0

Invoke-RestMethod -Uri 'http://ipinfo.io'
```

结果大概如下：

```
ip       : 80.187.113.144
hostname : tmo-113-144.customers.d1-online.com
region   : 
country  : DE
loc      : 51.2993,9.4910
org      : AS3320 Deutsche Telekom AG
```

<!--本文国际来源：[Get GeoLocation of Computer](http://community.idera.com/powershell/powertips/b/tips/posts/get-geolocation-of-computer)-->
