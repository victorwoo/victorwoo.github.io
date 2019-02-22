---
layout: post
date: 2015-09-22 11:00:00
title: "PowerShell 技能连载 - 设置新的 Windows 注册所有者"
description: PowerTip of the Day - Setting New Windows Registered Owner
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
这一小段代码将提示输入新的注册所有者名，然后将更新 Windows 注册表中的值。请注意需要管理员权限。

    #requires -RunAsAdministrator
    
    
    $NewName = Read-Host -Prompt 'Enter New Registered Windows Owner'
    
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name RegisteredOwner -Value $NewName -Type String

这也是一个更改 Windows 注册表的模板代码。

<!--本文国际来源：[Setting New Windows Registered Owner](http://community.idera.com/powershell/powertips/b/tips/posts/setting-new-windows-registered-owner)-->
