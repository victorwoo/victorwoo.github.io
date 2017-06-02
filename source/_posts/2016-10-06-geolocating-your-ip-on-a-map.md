---
layout: post
date: 2016-10-06 00:00:00
title: "PowerShell 技能连载 - 在地图上定位您的地理位置"
description: PowerTip of the Day - Geolocating Your IP on a Map
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
在前一个技能当中，通过 Internet 能知道您的 IP 地址，以及地理位置。您可以获得当前公开 IP 地址的经纬度，代码如下：

```powershell
$ip = Invoke-RestMethod -Uri http://checkip.amazonaws.com/ 
$geo = Invoke-RestMethod -Uri "http://geoip.nekudo.com/api/$IP" 
$latitude = $geo.Location.Latitude
$longitude = $geo.Location.Longitude

"Lat $latitude Long $longitude"
```

如果您希望看到它究竟在什么位置，可以将这些信息连到 Google Maps 上：

```powershell
$ip = Invoke-RestMethod -Uri http://checkip.amazonaws.com/ 
$geo = Invoke-RestMethod -Uri "http://geoip.nekudo.com/api/$IP" 
$latitude = $geo.Location.Latitude
$longitude = $geo.Location.Longitude

$url = "https://www.google.com/maps/preview/@$latitude,$longitude,8z"
Start-Process -FilePath $url
```

这段代码将打开浏览器，导航到 Google Maps，并且在地图上显示当前位置。当前通过 IP 地址定位地理位置还比较粗糙，至少在使用公开地理数据时。

<!--more-->
本文国际来源：[Geolocating Your IP on a Map](http://community.idera.com/powershell/powertips/b/tips/posts/geolocating-your-ip-on-a-map)
