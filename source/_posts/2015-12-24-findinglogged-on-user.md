layout: post
date: 2015-12-24 12:00:00
title: "PowerShell 技能连载 - 查询当前登录的用户名"
description: PowerTip of the Day - Finding Logged On User
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
有两种方式可以查询当前登录的用户：

    # User logged on to a physical box
    Get-WmiObject -Class Win32_ComputerSystem | Select-object -ExpandProperty UserName
    
    
    # Owners of explorer.exe processes (desktop is an Explorer process)
    Get-WmiObject -Class Win32_Process -Filter 'Name="explorer.exe"'  |
      ForEach-Object {
        $owner = $_.GetOwner()
        '{0}\{1}' -f  $owner.Domain, $owner.User
      } |
      Sort-Object -Unique

两种使用 `Get-WmiObject` 的方式都支持本地和远程方式调用。

<!--more-->
本文国际来源：[Finding Logged On User](http://community.idera.com/powershell/powertips/b/tips/posts/findinglogged-on-user)
