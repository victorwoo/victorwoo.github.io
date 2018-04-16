---
layout: post
date: 2018-04-13 00:00:00
title: "PowerShell 技能连载 - 从 Internet 下载信息（第 1 部分）"
description: PowerTip of the Day - Downloading Information from Internet (Part 1)
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
PowerShell 带来了两个 cmdlet，可以用来从 internet 获取信息。今天，我们重点关注 `Invoke-WebRequest`。

这个 cmdlet 提供了一个简单的 web 客户端。传给它一个 URL，它就可以帮您下载该网页。以下简单的几行代码可以帮您下载 psconf.eu 的议程表：

```powershell
$page = Invoke-WebRequest -Uri powershell.beer -UseBasicParsing 
$page.Content
```

由于它是 JSON 格式的，所以可以将它通过管道传递给 `ConvertFrom-Json` 来获得对象：

```powershell
$page = Invoke-WebRequest -Uri powershell.beer -UseBasicParsing 
$page.Content | ConvertFrom-Json | Out-GridView
```

然而，有些时候（例如这个例子），它并不能正确地“展开”集合结果，所以得手工操作它：

```powershell
$page = Invoke-WebRequest -Uri powershell.beer -UseBasicParsing 
$($page.Content | ConvertFrom-Json) | Out-GridView
```

通过这种方法，您可以下载网页上的任意信息，然后处理它。如果一个 web 页返回的是 XML，您可以将它转换为 XML，而如果它是纯 HTML，您可以使用正则表达式来提取您需要的信息。更多信息请见将来的技能。

<!--more-->
本文国际来源：[Downloading Information from Internet (Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/downloading-information-from-internet-part-1)
