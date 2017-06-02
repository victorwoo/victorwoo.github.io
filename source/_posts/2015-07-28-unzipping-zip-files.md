---
layout: post
date: 2015-07-28 11:00:00
title: "PowerShell 技能连载 - 解压 ZIP 文件"
description: PowerTip of the Day - Unzipping ZIP Files
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
在 PowerShell 5.0 中，有一个新的 cmdlet 可以解压 ZIP 文件：

    #requires -Version 5
    
    $Source = 'C:\somezipfile.zip'
    $Destination = 'C:\somefolder'
    $Overwrite = $true
    $ShowDestinationFolder = $true
    
    Expand-Archive -Path $Source -DestinationPath $Destination -Force:$Overwrite
    
    if ($ShowDestinationFolder)
    {
      explorer.exe $Destination
    }

<!--more-->
本文国际来源：[Unzipping ZIP Files](http://community.idera.com/powershell/powertips/b/tips/posts/unzipping-zip-files)
