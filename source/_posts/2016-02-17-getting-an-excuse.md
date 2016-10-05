layout: post
date: 2016-02-17 12:00:00
title: "PowerShell 技能连载 - 得到一个借口"
description: PowerTip of the Day - Getting an Excuse
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
以下是一个快速的方法来得到一个借口——假设您有 Internet 连接：

    #requires -Version 3
    function Get-Excuse
    {
      $url = 'http://pages.cs.wisc.edu/~ballard/bofh/bofhserver.pl'
      $ProgressPreference = 'SilentlyContinue'
      $page = Invoke-WebRequest -Uri $url -UseBasicParsing
      $pattern = '(?m)<br><font size = "\+2">(.+)'
      if ($page.Content -match $pattern)
      {
        $matches[1]
      }
    }

它演示了如何使用 `Invoke-WebRequest` 来下载一个网页的 HTML 内容，然后使用正则表达式来抓取网页的内容。

<!--more-->
本文国际来源：[Getting an Excuse](http://community.idera.com/powershell/powertips/b/tips/posts/getting-an-excuse)
