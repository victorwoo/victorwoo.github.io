---
layout: post
date: 2019-06-24 00:00:00
title: "PowerShell 技能连载 - 使用 GeoCoding：将地址转换为经纬度（第 2 部分）"
description: 'PowerTip of the Day - Geocoding: Converting Addresses to Lat/Long (Part 2)'
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
让我们从将地址转换为经纬度坐标开始。我们假设您已经阅读了前面的部分以完全理解代码示例。

下面是一些示例代码，它接受任意数量的地址，并返回它们的经纬度：

```powershell
'One Microsoft Way, Redmond',
'Bahnhofstrasse 12, Hannover, Germany' |
  ForEach-Object -Begin {$url = 'https://geocode.xyz'
    $null = Invoke-RestMethod $url -S session
  } -Process {
    $address = $_
    $encoded = [Net.WebUtility]::UrlEncode($address)
    Invoke-RestMethod "$url/${encoded}?json=1" -W $session|
      ForEach-Object {
        [PSCustomObject]@{
          Address = $address
          Long = $_.longt
          Lat = $_.latt
        }
      }
  }
```

结果看起来类似这样：

    Address                              Long       Lat
    -------                              ----       ---
    One Microsoft Way, Redmond           -122.13061 47.64373
    Bahnhofstrasse 12, Hannover, Germany 9.75195    52.37799

<!--本文国际来源：[Geocoding: Converting Addresses to Lat/Long (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/geocoding-converting-addresses-to-lat-long-part-2)-->

