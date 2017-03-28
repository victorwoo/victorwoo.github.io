layout: post
date: 2016-10-17 00:00:00
title: "PowerShell 技能连载 - 查找隐藏的自启动程序"
description: PowerTip of the Day - Finding Hidden Autostart Programs
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
Ever wondered why some programs launch whenever you log into Windows? Here’s a one liner listing autostarts that affect your login:
是否好奇为什么有些程序在登录 Windows 的时候会自动启动？这是一行列出登录时自启动项的代码：

```powershell
#requires -Version 3

Get-CimInstance -ClassName Win32_StartupCommand |
  Select-Object -Property Command, Description, User, Location |
  Out-GridView
```

<!--more-->
本文国际来源：[Finding Hidden Autostart Programs](http://community.idera.com/powershell/powertips/b/tips/posts/finding-hidden-autostart-programs)
