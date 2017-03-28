layout: post
date: 2015-04-14 11:00:00
title: "PowerShell 技能连载 - 查找电视剧信息"
description: PowerTip of the Day - Finding Information about TV Series
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
PowerShell 可以查询基于 XML 内容的网站，以下是一个查询电影数据库的例子：

只需要输入您感兴趣的电视剧名称即可。如果您不能直接访问 Internet，可以用 `-Proxy` 参数指定代理服务器。

    #requires -Version 3
    
    $name = 'stargate'
    $url = "http://thetvdb.com/api/GetSeries.php?seriesname=$name&language=en"
    
    $page = Invoke-WebRequest -Uri $url <#-Proxy 'http://proxy....:8080' -ProxyUseDefaultCredentials#>
    $content = $page.Content
    
    
    $xml = [XML]$content
    $xml.Data.Series | Out-GridView

<!--more-->
本文国际来源：[Finding Information about TV Series](http://community.idera.com/powershell/powertips/b/tips/posts/finding-information-about-tv-series)
