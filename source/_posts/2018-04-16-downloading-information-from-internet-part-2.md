---
layout: post
date: 2018-04-16 00:00:00
title: "PowerShell 技能连载 - 从 Internet 下载信息（第 2 部分）"
description: PowerTip of the Day - Downloading Information from Internet (Part 2)
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
`Invoke-WebRequest` 可以下载任意类型的信息，而且可以根据您的需要将它转为任意类型。在前一个技能里，我们演示了如何处理 JSON 数据。现在我们来看看返回 XML 数据的网页：

这个例子从欧洲中央银行获取当前的货币兑换率：

```powershell
$url = 'http://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml'
$result = Invoke-WebRequest -Uri $url -UseBasicParsing
$result.Content
```

以下是结果：

```powershell
$url = 'http://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml'
$result = Invoke-WebRequest -Uri $url -UseBasicParsing
$xml = [xml]$result.Content
$xml.Envelope.Cube.Cube.Cube
```

<!--more-->
本文国际来源：[Downloading Information from Internet (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/downloading-information-from-internet-part-2)
