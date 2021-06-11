---
layout: post
date: 2021-04-05 00:00:00
title: "PowerShell 技能连载 - 观看德国电视节目"
description: PowerTip of the Day - Watching German TV Shows
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
德国公共广播公司保留着丰富的电视档案，并允许用户通过 Web 界面观看其节目。通常无法下载节目或轻松找到其下载 URL。

以下脚本下载了所有节目及其网络位置的非官方目录：

```powershell
# download the German mediathek database as JSON file
$path = "$env:temp\tv.json"
$url = 'http://www.mediathekdirekt.de/good.json'
Invoke-RestMethod -Uri $url -UseBasicParsing -OutFile $path
```

下载该文件后，您可以使用其他脚本来显示选择对话框，并浏览要观看的电视节目。然后，您可以选择一个或多个节目，并要求 PowerShell 将这些视频自动下载到您的计算机上。

```powershell
$Path = "$env:temp\tv.json"

$data = Get-Content -Path $Path -Raw |
ConvertFrom-Json |
ForEach-Object { $_ } |
ForEach-Object {
  # define a string describing the video. This string will be shown in a grid view window
  $title = '{0,5} [{2}] "{1}" ({3})' -f ([Object[]]$_)
  # add the original data to the string so when the user select a video,
  # the details i.e. download URL is still available
  $title | Add-Member -MemberType NoteProperty -Name Data -Value $_ -PassThru
}

$data |
Sort-Object |
Out-GridView -Title 'Select Video(s)' -OutputMode Multiple |
ForEach-Object {
  # take the download URL from the attached original data
  $url = $_.Data[5]
  $filename = Split-Path -Path $url -Leaf
  $filepath = Join-Path -Path $env:temp -ChildPath $filename
  $title = 'Video download {0} ({1})' -f $_.Data[1], $_.Data[0]
  Start-BitsTransfer -Description $title -Source $url -Destination $filepath
  # you can use a simple web request as well in case BITS isn't available
  # Invoke-WebRequest -Uri $url -OutFile $filepath -UseBasicParsing

  # open video in associated player
  Invoke-Item -Path $filepath
}
```

<!--本文国际来源：[Watching German TV Shows](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/watching-german-tv-shows)-->

