---
layout: post
date: 2016-09-05 00:00:00
title: "PowerShell 技能连载 - 查找自启动项"
description: PowerTip of the Day - Finding Auto Starts
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
*支持 PowerShell 3 以上版本*

If you’d like to know which programs start automatically on your machine, WMI may help:

如果您想了解有多少个程序随着您的机器自动启动，WMI 也许能帮上忙：


```shell
PS C:\> Get-CimInstance -ClassName Win32_StartupCommand | Select-Object -Property Name, Location, User, Command, Description

Name        : OneDrive
Location    : HKU\S-1-5-21-2012478179-265285931-690539891-1001\SOFTWARE\Microsoft\Windows\CurrentVersion\Run
User        : DESKTOP-7AAMJLF\tobwe
Command     : "C:\Users\tobwe\AppData\Local\Microsoft\OneDrive\OneDrive.exe" /background
Description : OneDrive

Name        : Bluetooth
Location    : Common Startup
User        : Public
Command     : C:\PROGRA~1\WIDCOMM\BLUETO~1\BTTray.exe 
Description : Bluetooth

Name        : Snagit 12
Location    : Common Startup
User        : Public
Command     : C:\PROGRA~2\TECHSM~1\SNAGIT~1\Snagit32.exe 
Description : Snagit 12

Name        : RTHDVCPL
Location    : HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run
User        : Public
Command     : "C:\Program Files\Realtek\Audio\HDA\RtkNGUI64.exe" -s
Description : RTHDVCPL

...
```

<!--more-->
本文国际来源：[Finding Auto Starts](http://community.idera.com/powershell/powertips/b/tips/posts/finding-auto-starts)
