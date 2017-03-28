layout: post
date: 2016-10-05 00:00:00
title: "PowerShell 技能连载 - 查找公开 IP 地址"
description: PowerTip of the Day - Finding Public IP Address
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
您是否希望了解您当前连接到 Internet 的公开 IP 地址？以下是一行代码：

```powershell
#requires -Version 3.0
Invoke-RestMethod -Uri http://checkip.amazonaws.com/
```

通过这个 IP 地址，您还可以向 Internet 请求您的地理地址：

```powershell
#requires -Version 3.0
$ip = Invoke-RestMethod -Uri http://checkip.amazonaws.com/ 
Invoke-RestMethod -Uri "http://geoip.nekudo.com/api/$IP" |
  Select-Object -ExpandProperty Country
```

<!--more-->
本文国际来源：[Finding Public IP Address](http://community.idera.com/powershell/powertips/b/tips/posts/finding-public-ip-address1)
