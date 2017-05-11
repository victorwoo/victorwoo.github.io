layout: post
date: 2017-05-05 00:00:00
title: "PowerShell 技能连载 - 从德国媒体数据库下载视频"
description: PowerTip of the Day - Downloading Videos From German Media Databases
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
在德国，有一些公开的媒体数据库，里面有公共站点发布的电视内容。只需要用一小段 PowerShell 代码就可以解析 JSON 数据，在一个列表中显示电视节目，并使你能够选择某项来下载。

请注意包含下载链接的 JSON 文件非常大，所以需要过一段时间才能显示出视频列表。

```powershell
#requires -Version 3.0

# here is the list of download URLs - get it and 
# convert the JSON format
$url = 'http://www.mediathekdirekt.de/good.json'
$web = Invoke-WebRequest -Uri $url -UseBasicParsing 
$videos = $web.Content | ConvertFrom-Json 

# get all videos, create a nice title to display,
# and attach the original data to each entry
$videos |
ForEach-Object {
  $title = '{0} - {1}' -f $_[2], $_[5]
  $title | Add-Member -MemberType NoteProperty -Name Data -Value $_ -PassThru
} |
Sort-Object |
Out-GridView -Title 'Video' -OutputMode Multiple |
ForEach-Object {
  # get the actual download info from the selected videos
  # and do the download
  $url = $_.Data[6]
  $filename = Split-Path -Path $url -Leaf
  # videos are saved into your TEMP folder unless you
  # specify a different folder below
  $filepath = Join-Path -Path $env:temp -ChildPath $filename
  Invoke-WebRequest -Uri $url -OutFile $filepath -UseBasicParsing
  Invoke-Item -Path $filepath
}
```

<!--more-->
本文国际来源：[Downloading Videos From German Media Databases](http://community.idera.com/powershell/powertips/b/tips/posts/downloading-videos-from-german-media-databases)
