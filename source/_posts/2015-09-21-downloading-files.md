---
layout: post
date: 2015-09-21 11:00:00
title: "PowerShell 技能连载 - 下载文件"
description: PowerTip of the Day - Downloading Files
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`Invoke-WebRequest` 可以从 internet 下载文件。这个例子将下载一个 33MB 的 NASA 公开视频到您的计算机上，然后用您计算机上 WMV 视频文件的关联应用打开它：

    #requires -Version 3
    
    $Video = 'http://s3.amazonaws.com/akamai.netstorage/HD_downloads/BEAMextract_final_revB.wmv'
    $Destination = "$env:temp\nasavideo1.wmv"
    Invoke-WebRequest -Uri $Video -OutFile $Destination -UseBasicParsing
    
    Invoke-Item -Path $Destination

<!--本文国际来源：[Downloading Files](http://community.idera.com/powershell/powertips/b/tips/posts/downloading-files)-->
