layout: post
title: "PowerShell 技能连载 - 查找注册的事件源"
date: 2014-04-23 00:00:00
description: PowerTip of the Day - Finding Registered Event Sources
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
每个 Windows 日志文件都有一个注册的事件源列表。要找出哪个事件源注册到哪个事件日志，您可以直接查询 Windows 注册表。

这段代码将列出所有注册到“System”事件日志的事件源：

    $LogName = 'System'
    $path = "HKLM:\System\CurrentControlSet\services\eventlog\$LogName"
    Get-ChildItem -Path $path -Name 

<!--more-->
本文国际来源：[Finding Registered Event Sources](http://community.idera.com/powershell/powertips/b/tips/posts/finding-registered-event-sources)
