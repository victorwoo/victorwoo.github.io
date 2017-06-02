---
layout: post
date: 2015-12-28 12:00:00
title: "PowerShell 技能连载 - 强制用户修改密码"
description: PowerTip of the Day - Force User to Change Password
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
使用这段代码片段可以强制用户改变他/她的密码：

    #requires -Version 1 -Modules ActiveDirectory
    
    Set-ADUser -Identity username -ChangePasswordAtNextLogon $true

<!--more-->
本文国际来源：[Force User to Change Password](http://community.idera.com/powershell/powertips/b/tips/posts/force-user-to-change-password)
