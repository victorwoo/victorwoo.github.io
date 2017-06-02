---
layout: post
date: 2015-04-16 11:00:00
title: "PowerShell 技能连载 - 读取 RSS 频道"
description: PowerTip of the Day - Reading RSS Feeds
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
我们可以通过 XML 对象来读取 RSS 频道信息，然而 XML 对象不支持代理服务器。

这个例子用 `Invoke-WebRequest` 通过代理服务器来获取 RSS 数据（如果忽略 `-Proxy` 参数则直接获取），然后将结果转换为 XML。

    #requires -Version 3
    
    
    $url = 'http://blogs.msdn.com/b/powershell/rss.aspx'
    
    $page = Invoke-WebRequest -Uri $url <#-Proxy 'http://proxy...:8080' -ProxyUseDefaultCredentials#>
    $content = $page.Content
    
    
    $xml = [XML]$content
    $xml.rss.channel.item  | Out-GridView

这段代码将显示 PowerShell 团队博客数据。

<!--more-->
本文国际来源：[Reading RSS Feeds](http://community.idera.com/powershell/powertips/b/tips/posts/reading-rss-feeds)
