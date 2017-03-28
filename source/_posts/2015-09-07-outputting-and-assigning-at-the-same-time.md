layout: post
date: 2015-09-07 11:00:00
title: "PowerShell 技能连载 - 输出的同时赋值"
description: PowerTip of the Day - Outputting and Assigning at the Same Time
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
如果您想将某个命令的结果赋给一个变量，并且同时输出结果，以下是两种实现方法：

您可以使用小括号：

    PS> ($result = Get-Service)
    
    Status   Name               DisplayName
    ------   ----               -----------
    Running  AdobeARMservice    Adobe Acrobat Update Service
    (...)

或者使用 `OutVariable` 通用参数：

    PS> Get-Service -OutVariable result
    
    Status   Name               DisplayName
    ------   ----               -----------
    Running  AdobeARMservice    Adobe Acrobat Update Service
    (...)

<!--more-->
本文国际来源：[Outputting and Assigning at the Same Time](http://community.idera.com/powershell/powertips/b/tips/posts/outputting-and-assigning-at-the-same-time)
