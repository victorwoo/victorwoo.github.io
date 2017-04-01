layout: post
date: 2015-05-04 11:00:00
title: "PowerShell 技能连载 - 谁在使用网络资源？"
description: PowerTip of the Day - Who is Accessing Network Resources?
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
假设您拥有管理员权限，您可以使用一个简单的 WMI 类来检测某人是否正在通过网络访问您的资源：

    PS> Get-WmiObject -Class Win32_ServerConnection | 
    Select-Object -Property ComputerName, ConnectionID, UserName, ShareName 

这个操作也可以远程执行：只需要为 `Get-WmiObject` 命令增加 `-ComputerName` 参数即可查看谁在访问该远程计算机上的共享资源。需要拥有目标计算机的管理员权限才可以进行远程操作。

<!--more-->
本文国际来源：[Who is Accessing Network Resources?](http://community.idera.com/powershell/powertips/b/tips/posts/who-is-accessing-network-resources)
