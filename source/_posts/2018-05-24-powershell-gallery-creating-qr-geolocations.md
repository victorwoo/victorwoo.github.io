---
layout: post
date: 2018-05-24 00:00:00
title: "PowerShell 技能连载 - PowerShell 陈列架：创建地理位置二维码"
description: 'PowerTip of the Day - PowerShell Gallery: Creating QR GeoLocations'
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
在前一个技能中我们解释了如何获取 PowerShellGet 并在您的 PowerShell 版本中运行。现在我们来看看 PowerShell 陈列架能够如何方便地扩展 PowerShell 功能。

下次您发送会议、上课，或是派对邀请时，为啥不加上一个地理定位的二维码呢？大多数现代的智能设备可以通过它们的相机 APP 扫描这些二维码，并且在地图中显示该地址，且提供如何到达该地址的路径。

创建一个地理位置二维码十分简单，因为困难的部分已经由 `QRCodeGenerator` 模块实现了：

```powershell
# adjust this to match your own info
$first = "Tom"
$last = "Sawywer"
$company = "freelancer.com"
$email = "t.sawyer@freelancer.com"


# QR Code will be saved here
$path = "$home\Desktop\locationQR.png"

# install the module from the Gallery (only required once)
Install-Module QRCodeGenerator -Scope CurrentUser -Force
# create QR code via address (requires internet access and Google API to work)
New-QRCodeGeolocation -OutPath $path -Address 'Bahnhofstrasse 12, Essen'

# open QR code image with an associated program
Invoke-Item -Path $path
```

当您在上述例子中传入一个地址，它将自动通过 Google 免费的 API 翻译成经纬度。这可能并不总是起作用，并且需要 Internet 连接。如果您知道您的位置的经纬度，您当然也可以通过 `-Latitude` 和 `Longitude` 参数传入经纬度。

<!--more-->
本文国际来源：[PowerShell Gallery: Creating QR GeoLocations](http://community.idera.com/powershell/powertips/b/tips/posts/powershell-gallery-creating-qr-geolocations)
