---
layout: post
title: "PowerShell 技能连载 - 在 PowerShell 中提升命令权限"
date: 2014-03-19 00:00:00
description: PowerTip of the Day - Running Commands Elevated in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有些时候，一个脚本需要运行一个需提升（管理员）权限的命令。

一种方法是将用管理员权限运行整个脚本，另一种方法是将独立的命令送到提升权限的 shell 中执行。

这段代码将重启 Spooler 服务（需要提升权限），并将命令发送到另一个 PowerShell 进程中。如果当前进程没有管理员权限，它将自动提升权限。

    $command = 'Restart-Service -Name spooler'
    Start-Process -FilePath powershell.exe -ArgumentList "-noprofile -command $Command" `  
    -Verb runas 

<!--本文国际来源：[Running Commands Elevated in PowerShell](http://community.idera.com/powershell/powertips/b/tips/posts/running-commands-elevated-in-powershell)-->
