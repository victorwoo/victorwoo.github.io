---
layout: post
date: 2018-09-14 00:00:00
title: "PowerShell 技能连载 - 通过 SSL 和 Invoke-WebRequest 下载数据"
description: PowerTip of the Day - Downloading Data via SSL and Invoke-WebRequest
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
`Invoke-WebRequest` 可以下载文件，但是对 HTTPS URL 可能会遇到麻烦。要使用 SSL 连接，您可能需要改变缺省的设置。以下是一个可用的示例：

```powershell
$url = 'https://mars.nasa.gov/system/downloadable_items/41764_20180703_marsreport-1920.mp4'
$OutFile = "$home\desktop\video.mp4"

$AllProtocols = [Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
[Net.ServicePointManager]::SecurityProtocol = $AllProtocols
Invoke-WebRequest -OutFile $OutFile -UseBasicParsing -Uri $url
```

<!--more-->
本文国际来源：[Downloading Data via SSL and Invoke-WebRequest](http://community.idera.com/powershell/powertips/b/tips/posts/downloading-data-via-ssl-and-invoke-webrequest)
