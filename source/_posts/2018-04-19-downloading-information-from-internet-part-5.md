---
layout: post
date: 2018-04-19 00:00:00
title: "PowerShell 技能连载 - 从 Internet 下载信息（第 5 部分）"
description: PowerTip of the Day - Downloading Information from Internet (Part 5)
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
在前一个技能中我们演示了如何使用 `Invoke-WebRequest` 从网页下载 JSON 或 XML 数据。这个例子从 psconf.eu 下载 JSON 格式的议程表：

```powershell
$page = Invoke-WebRequest -Uri powershell.beer -UseBasicParsing $($page.Content | ConvertFrom-Json) | Out-GridView
```

这个例子下载 XML 格式的货币兑换率：

```powershell
$url = 'http://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml'$result = Invoke-WebRequest -Uri $url -UseBasicParsing$xml = [xml]$result.Content$xml.Envelope.Cube.Cube.Cube 
```

现在，有另一个名为 `Invoke-RestMethod` 的 cmdlet，专门设计来获取对象数据。基本上，它的工作方式和 `Invoke-WebRequest` 很接近，但是能够自动识别数据格式，并相应地转换它的类型。以下是用一行代码获取 psconf.eu 议程表的例子：

```powershell
$(Invoke-RestMethod -Uri powershell.beer -UseBasicParsing) | Out-GridView
```

这是轻松地获取货币兑换率的方法：

```powershell
$url = 'http://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml'
(Invoke-RestMethod -Uri $url -UseBasicParsing).Envelope.Cube.Cube.Cube
```

<!--more-->
本文国际来源：[Downloading Information from Internet (Part 5)](http://community.idera.com/powershell/powertips/b/tips/posts/downloading-information-from-internet-part-5)
