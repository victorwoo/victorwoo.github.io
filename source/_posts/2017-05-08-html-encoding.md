layout: post
date: 2017-05-08 00:00:00
title: "PowerShell 技能连载 - HTML 编码"
description: PowerTip of the Day - HTML Encoding
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
有一个 .NET 的静态方法可以对一段文本进行 HTML 编码，例如如果您希望在 HTML 输出中正常显示一段文本：

```powershell     
PS>  [System.Web.HttpUtility]::HtmlEncode('Österreich heißt so.')
&#214;sterreich hei&#223;t so.
```

<!--more-->
本文国际来源：[HTML Encoding](http://community.idera.com/powershell/powertips/b/tips/posts/html-encoding)
