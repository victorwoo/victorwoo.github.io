layout: post
date: 2014-12-12 12:00:00
title: "PowerShell 技能连载 - 获取系统启动时间"
description: PowerTip of the Day - Getting System Uptime
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

这个简单的函数可以返回当前系统的启动时间：

    function Get-Uptime 
    {
      $millisec = [Environment]::TickCount
      [Timespan]::FromMilliseconds($millisec)
    }

<!--more-->
本文国际来源：[Getting System Uptime](http://community.idera.com/powershell/powertips/b/tips/posts/gettingsystemuptime)
