---
layout: post
title: "PowerShell 技能连载 - 通过 Google 图片搜索自动下载图片"
date: 2014-04-25 00:00:00
description: PowerTip of the Day - Automatically Downloading Pictures via Google Picture Search
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技巧中您学到了如何用 `Invoke-WebRequest` 从 Google 图片搜索中获取图片链接。`Invoke-WebRequest` 还可以做更多的东西。它可以获取图片 URL 并下载图片。

以下是具体做法：

    $SearchItem = 'PowerShell'
    $TargetFolder = 'c:\webpictures'
    
    if ( (Test-Path -Path $TargetFolder) -eq $false) { md $TargetFolder }
    
    explorer.exe $TargetFolder
    
    $url = "https://www.google.com/search?q=$SearchItem&espv=210&es_sm=93&source=lnms&tbm=isch&sa=X&tbm=isch&tbs=isz:lt%2Cislt:2mp"
    
    $browserAgent = 'Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/33.0.1750.146 Safari/537.36'
    $page = Invoke-WebRequest -Uri $url -UserAgent $browserAgent
    $page.Links | 
      Where-Object { $_.href -like '*imgres*' } | 
      ForEach-Object { ($_.href -split 'imgurl=')[-1].Split('&')[0]} |
      ForEach-Object {
        $file = Split-Path -Path $_ -Leaf
        $path = Join-Path -Path $TargetFolder -ChildPath $file
        Invoke-WebRequest -Uri $_ -OutFile $path
      } 

您可以下载所有匹配关键字“PowerShell”的高分辨率的图片到您指定的 $TargetFolder 文件夹中。

<!--本文国际来源：[Automatically Downloading Pictures via Google Picture Search](http://community.idera.com/powershell/powertips/b/tips/posts/automatically-downloading-pictures-via-google-picture-search)-->
