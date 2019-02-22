---
layout: post
date: 2018-09-17 00:00:00
title: "PowerShell 技能连载 - 通过 SSL 和 BitsTransfer"
description: PowerTip of the Day - Downloading Data via SSL and BitsTransfer (Sync)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有一个很实用的内置方法可以下载文件，甚至支持 SSL 连接。该方法是 `Start-BitsTransfer`。它也会显示一个进度条，指示实际的下载状态。以下是一个可用的例子：

```powershell
$url = 'https://mars.nasa.gov/system/downloadable_items/41764_20180703_marsreport-1920.mp4'
$OutFile = "$home\desktop\videoNasa2.mp4"


Start-BitsTransfer -Source $url -Destination $OutFile -Priority Normal -Description 'NASA Movie'
```

<!--本文国际来源：[Downloading Data via SSL and BitsTransfer (Sync)](http://community.idera.com/powershell/powertips/b/tips/posts/downloading-data-via-ssl-and-bitstransfer-sync)-->
