layout: post
date: 2015-08-25 11:00:00
title: "PowerShell 技能连载 - 以管理员身份执行指定的代码"
description: PowerTip of the Day - Executing Selected Code as Admin
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
如果您需要以管理员身份运行指定的脚本片段，您可以以管理员身份临时创建第二个 PowerShell 实例，然后在临时的实例中执行特权代码。

这是一段停止 Windows 更新服务的例子。当您以普通用户运行这段代码时，它将自动弹出提权的对话框，然后在一个新的管理员外壳中执行您的代码：

    #requires -Version 2
    
    Start-Process -FilePath powershell.exe -Verb runas -ArgumentList 'Stop-Service -Name wuauserv' -WindowStyle Minimized

<!--more-->
本文国际来源：[Executing Selected Code as Admin](http://community.idera.com/powershell/powertips/b/tips/posts/executing-selected-code-as-admin)
