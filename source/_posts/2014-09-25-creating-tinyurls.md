layout: post
date: 2014-09-25 11:00:00
title: "PowerShell 技能连载 - 创建短网址"
description: PowerTip of the Day - Creating TinyURLs
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
_适用于 PowerShell 所有版本_

您也许听说过长网址的缩短服务。有许多这类免费的服务。以下是一个将任何网址转化为短网址的脚本：

    $OriginalURL = 'http://www.powertheshell.com/isesteroids2'
    
    $url = "http://tinyurl.com/api-create.php?url=$OriginalURL"
    $webclient = New-Object -TypeName System.Net.WebClient
    $webclient.DownloadString($url) 

只需要将需要缩短的网址赋给 `$OriginalURL`，运行脚本。它将返回对应的短网址。

<!--more-->
本文国际来源：[Creating TinyURLs](http://community.idera.com/powershell/powertips/b/tips/posts/creating-tinyurls)
