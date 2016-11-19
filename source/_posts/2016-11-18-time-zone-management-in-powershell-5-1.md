layout: post
date: 2016-11-17 16:00:00
title: "PowerShell 技能连载 - PowerShell 5.1 中的时区管理"
description: PowerTip of the Day - Time Zone Management in PowerShell 5.1
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
PowerShell 5.1（随 Windows 10 和 Server 2016 发布）带来一系列管理计算机时区的新 cmdlet。`Get-TimeZone` 返回当前的设置，而 `Set-TimeZone` 可以改变时区设置：

    PS C:\> Get-TimeZone
    
    Id                         : W. Europe Standard Time
    DisplayName                : (UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, 
                                 Vienna
    StandardName               : W. Europe Standard Time
    DaylightName               : W. Europe Daylight Time
    BaseUtcOffset              : 01:00:00
    SupportsDaylightSavingTime : True


<!--more-->
本文国际来源：[Time Zone Management in PowerShell 5.1](http://community.idera.com/powershell/powertips/b/tips/posts/time-zone-management-in-powershell-5-1)
