---
layout: post
date: 2017-09-21 00:00:00
title: "PowerShell 技能连载 - 还原 TinyUrl 的真实地址"
description: "PowerTip of the Day - Uncovering TinyUrls’ True Origin"
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
URL 缩短功能对于 Twitter 消息十分有用，但是隐藏了真实地址。您是否真的信任 http://bit.ly/e0Mw9w 呢？

以下是一个简单的方法，帮您还原缩短后的 URL 指向的真实地址：

```powershell
$shortUrl = "http://bit.ly/e0Mw9w"

$longURL = Invoke-WebRequest -Uri "http://untiny.me/api/1.0/extract?url=$shortUrl&format=text" -UseBasicParsing |
                Select-Object -ExpandProperty Content

"'$shortUrl' -> '$longUrl'"
```

如您所见，这个例子中缩短的 URL 指向的是 Lee Holmes 的博客：http://www.leeholmes.com/projects/ps_html5/Invoke-PSHtml5.ps1。Lee Holmes 是一个 PowerShell 团队成员，如果您信任他，那么可以好奇地运行他著名的代码片段：

```powershell
iex (New-Object Net.WebClient).DownloadString("http://bit.ly/e0Mw9w")
```

这是一个能说明 `Invoke-Expression` 别名为“iex”有危险的很好例子。

<!--more-->
本文国际来源：[Uncovering TinyUrls’ True Origin](http://community.idera.com/powershell/powertips/b/tips/posts/uncovering-tinyurls-true-origin)
