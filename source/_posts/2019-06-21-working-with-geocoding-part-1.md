---
layout: post
date: 2019-06-21 00:00:00
title: "PowerShell 技能连载 - 使用 GeoCoding（第 1 部分）"
description: PowerTip of the Day - Working with GeoCoding (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
去年，Google 改变了他们的服务条款，要求使用一个独立的 API 入口来使用他们的 geocode API。幸运的是，还有免费的替代，所以在这个迷你系列中我们想向您展示 PowerShell 可以如何处理地址和坐标。

所有这些功能需要 REST API 调用，所以无论需要通过 REST API 发送什么信息，都需要先编码成能做为 Web URL 的一部分发送的格式。

我们先聚焦在如何将文本编码为 REST API 调用的一部分：

```powershell
$address = 'Bahnhofstrasse 12, Hannover'
$encoded = [Net.WebUtility]::UrlEncode($address)
$encoded
```

当您查看结果时，您可以很容易地看到进行了许多修改：

    Bahnhofstrasse+12%2C+Hannover

<!--本文国际来源：[Working with GeoCoding (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/working-with-geocoding-part-1)-->

