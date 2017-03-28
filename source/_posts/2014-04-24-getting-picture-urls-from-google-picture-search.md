layout: post
title: "PowerShell 技能连载 - 从 Google 图片搜索中获取图片 URL"
date: 2014-04-24 00:00:00
description: PowerTip of the Day - Getting Picture URLs from Google Picture Search
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
当您想从互联网下载信息时，`Invoke-WebRequest` 是您的好帮手。例如，您可以发送一个请求到 Google 并使用 PowerShell 检验它的结果。

Google 也知道您在这么做，所以当您从 PowerShell 发送一个查询时，Google 返回加密的链接。要获取真实的链接，您需要告诉 Google 您使用的不是 PowerShell 而是一个普通的浏览器。这可以通过设置浏览器代理字符串。

这段脚本输入一个关键字并返回所有符合搜索关键字，并且大于 2 兆像素的所有图片的原始地址：

    $SearchItem = 'PowerShell'
    
    $url = "https://www.google.com/search?q=$SearchItem&espv=210&es_sm=93&source=lnms&tbm=isch&sa=X&tbm=isch&tbs=isz:lt%2Cislt:2mp"
    $browserAgent = 'Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/33.0.1750.146 Safari/537.36'
    $page = Invoke-WebRequest -Uri $url -UserAgent $browserAgent
    $page.Links | 
      Where-Object { $_.href -like '*imgres*' } | 
      ForEach-Object { ($_.href -split 'imgurl=')[-1].Split('&')[0]}  

<!--more-->
本文国际来源：[Getting Picture URLs from Google Picture Search](http://community.idera.com/powershell/powertips/b/tips/posts/getting-picture-urls-from-google-picture-search)
