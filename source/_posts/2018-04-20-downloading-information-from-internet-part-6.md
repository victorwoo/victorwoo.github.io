---
layout: post
date: 2018-04-20 00:00:00
title: "PowerShell 技能连载 - 从 Internet 下载信息（第 6 部分）"
description: PowerTip of the Day - Downloading Information from Internet (Part 6)
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
在之前的技能中我们介绍了如何用 `Invoke-WebRequest` 或 `Invoke-RestMethod` 从网页获取 XML 数据。对于 XML 数据，还有一种用 XML 对象自身内建方法的处理方法

这是 `Invoke-RestMethod` 的使用方法：

```powershell
$url = 'http://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml'
(Invoke-RestMethod -Uri $url -UseBasicParsing).Envelope.Cube.Cube.Cube
```

作为另一种选择，请试试这种方法：

```powershell
$url = 'http://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml'
$xml = New-Object -TypeName XML
$xml.Load($url)
$xml.Envelope.Cube.Cube.Cube
```

这种方法快得多。不过它没有提供 `Invoke-RestMethod` 中的多个参数来处理代理服务器和凭据。

<!--more-->
本文国际来源：[Downloading Information from Internet (Part 6)](http://community.idera.com/powershell/powertips/b/tips/posts/downloading-information-from-internet-part-6)
