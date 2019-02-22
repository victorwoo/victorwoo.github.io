---
layout: post
date: 2019-02-11 00:00:00
title: "PowerShell 技能连载 - 读取新闻订阅"
description: PowerTip of the Day - Reading News Feeds
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
以下是一个针对有德语技能的用户的特殊服务——对于其他人修改代码会有所挑战：以下代码使用了德国主要新闻杂志的 RSS 订阅，打开一个选择窗口。在窗口中您可以选择一篇或多篇文章，然后在缺省的浏览器中打开选择的文章：

```powershell
# URL to RSS Feed
$url = 'http://www.spiegel.de/schlagzeilen/index.rss'


$xml = New-Object -TypeName XML
$xml.Load($url)

# the subproperties (rss.channel.item) depend on the RSS feed you use
# and may be named differently
$xml.rss.channel.item  | 
  Select-Object -Property title, link |
  Out-GridView -Title 'What would you like to read today?' -OutputMode Multiple |
  ForEach-Object {
    Start-Process $_.link
  }
```

基本的设计过程是一致的：要将代码改为另一个 RSS 订阅，只需要导航到相应的属性（背后的 XML 的嵌套结构）。

<!--本文国际来源：[Reading News Feeds](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/reading-news-feeds)-->
