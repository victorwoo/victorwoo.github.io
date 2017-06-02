---
layout: post
date: 2015-09-23 11:00:00
title: "PowerShell 技能连载 - 修正远程发送者信息"
description: PowerTip of the Day - Fixing Remoting Sender Information
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
如果您使用 `Invoke-Command` 来远程执行 PowerShell 代码，您可能会注意到 PowerShell 远程操作会添加一个新的 `PSComputerName` 属性用来表示数据的来源。

这段代码将获取名为 _dc-01_ 的机器的进程列表。`PSComputerName` 属性指明了源计算机名。当您使用多于一台电脑时十分有用。

    #requires -Version 2
    $code = {
      Get-Process
    }
    
    Invoke-Command -ScriptBlock $code -ComputerName dc-01
    

然而，如果您将结果用管道输出到 `Out-GridView`，`PSComputerName` 属性消失了。

作为一个变通办法，当您将结果输出到 `Select-Object` 命令时，`PSComputerName` 属性将会在网格视图窗口中正确地显示。

    #requires -Version 2
    $code = {
      Get-Process |
        Select-Object -Property Name, ID, Handles, CPU
    }
    
    Invoke-Command -ScriptBlock $code -ComputerName dc-01 |
      Out-GridView

<!--more-->
本文国际来源：[Fixing Remoting Sender Information](http://community.idera.com/powershell/powertips/b/tips/posts/fixing-remoting-sender-information)
