---
layout: post
date: 2018-04-18 00:00:00
title: "PowerShell 技能连载 - 从 Internet 下载信息（第 4 部分）"
description: PowerTip of the Day - Downloading Information from Internet (Part 4)
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
在前一个技能中我们介绍了如何使用 `Invoke-WebRequest` 从网页下载数据，例如从一个提供随机借口的网页中获取借口。然而，当您做测试的时候，有可能每次都获取到相同的借口（或数据）。

```powershell
$url = 'http://pages.cs.wisc.edu/~ballard/bofh/bofhserver.pl'
$page = Invoke-WebRequest -Uri $url -UseBasicParsing
$content = $page.Content

$pattern = '(?s)<br><font size\s?=\s?"\+2">(.+)</font'

if ($page.Content -match $pattern)
{
    $matches[1]
}
```

最有可能的原因是处在一个代理服务器之后，代理服务器缓存了网站信息。要解决这个问题，只需要将 URL 加上一个类似这样的随机参数：

```powershell
$url = "http://pages.cs.wisc.edu/~ballard/bofh/bofhserver.pl?$(Get-Random)"
$page = Invoke-WebRequest -Uri $url -UseBasicParsing
$content = $page.Content

$pattern = '(?s)<br><font size\s?=\s?"\+2">(.+)</font'

if ($page.Content -match $pattern)
{
    $matches[1]
}
```

<!--more-->
本文国际来源：[Downloading Information from Internet (Part 4)](http://community.idera.com/powershell/powertips/b/tips/posts/downloading-information-from-internet-part-4)
