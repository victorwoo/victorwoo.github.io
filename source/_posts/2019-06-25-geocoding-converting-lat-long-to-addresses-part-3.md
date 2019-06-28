---
layout: post
date: 2019-06-25 00:00:00
title: "PowerShell 技能连载 - 使用 GeoCoding：将经纬度转换为地址（第 3 部分）"
description: 'PowerTip of the Day - Geocoding: Converting Lat/Long to Addresses (Part 3)'
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
今天，我们要做相反的事情，把经纬度转换成一个地址：

```powershell
'52.37799,9.75195' |
  ForEach-Object -Begin {$url='https://geocode.xyz'
    $null = Invoke-RestMethod $url -S session
  } -Process {
    $coord = $_
    Invoke-RestMethod "$url/${address}?geoit=json" -W $session
  }
```

<!--本文国际来源：[Geocoding: Converting Lat/Long to Addresses (Part 3)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/geocoding-converting-lat-long-to-addresses-part-3)-->

