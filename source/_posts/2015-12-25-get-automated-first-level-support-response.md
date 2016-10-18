layout: post
date: 2015-12-25 12:00:00
title: "PowerShell 技能连载 - 自动获取重要的支持响应信息"
description: PowerTip of the Day - Get Automated First Level Support Response
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
Here is a fun function to provide you with a good first level support response in case everyone is off for Christmas:
这是一个有趣的函数，当所有人都下班去过圣诞时将给您提供重要的支持响应信息。

    #requires -Version 3
    
    function Get-FirstLevelSupportResponse
    {
      $url = 'http://pages.cs.wisc.edu/~ballard/bofh/bofhserver.pl'
      $ProgressPreference = 'SilentlyContinue'
      $page = Invoke-WebRequest -Uri $url -UseBasicParsing
      $pattern = '(?s)<br><font size\s?=\s?"\+2">(.+)</font'
    
      if ($page.Content -match $pattern)
      {
        $matches[1]
      }
    }

您需要 Internet 连接来运行这段脚本。

<!--more-->
本文国际来源：[Get Automated First Level Support Response](http://community.idera.com/powershell/powertips/b/tips/posts/get-automated-first-level-support-response)
