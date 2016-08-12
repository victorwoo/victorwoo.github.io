layout: post
date: 2015-08-18 11:00:00
title: "PowerShell 技能连载 - 向对象增加额外信息"
description: PowerTip of the Day - Adding Additional Information to Objects
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
当您获取结果信息时，您可能会希望向结果对象添加一些额外的属性，这样待会儿就可以知道它们是从哪儿来的。

向复杂类型对象添加额外的信息和向简单数据类型添加额外的信息不同（在前一个技能中有介绍）。

    Get-Process |
      Add-Member -MemberType NoteProperty -Name PC -Value $env:COMPUTERNAME -PassThru |
      Select-Object -Property Name, Company, Description, PC |
      Out-GridView

这段代码中 `Get-Process` 返回的进程均被添加了一个名为“PC”的额外属性，用来存放进程所在的计算机名。

要查看自定义属性，要么使用 `Select-Object` 并指定属性名，要么使用点号语法：

    $list = Get-Process |
      Add-Member -MemberType NoteProperty -Name PC -Value $env:COMPUTERNAME -PassThru
    
    $list | ForEach-Object { 'Process {0} on {1}' -f $_.Name, $_.PC }

<!--more-->
本文国际来源：[Adding Additional Information to Objects](http://powershell.com/cs/blogs/tips/archive/2015/08/18/adding-additional-information-to-objects.aspx)
