layout: post
date: 2015-04-13 11:00:00
title: "PowerShell 技能连载 - 比较文件夹内容"
description: PowerTip of the Day - Comparing Folder Content
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
要快速比较文件夹内容并且找出只在一个文件夹中存在的文件，请试试以下代码：

    $list1 = Get-ChildItem c:\Windows\system32 | Sort-Object -Property Name
    
    $list2 = Get-ChildItem \\server12\c$\windows\system32 | Sort-Object -Property Name
    
    
    Compare-Object -ReferenceObject $list1 -DifferenceObject $list2 -Property Name | 
      Sort-Object -Property Name

该代码属两个文件夹列表，一个来自本机，另一个来自远程计算机。接下来 `Compare-Object` 命令会挑出只在一个文件夹中存在的文件。

<!--more-->
本文国际来源：[Comparing Folder Content](http://community.idera.com/powershell/powertips/b/tips/posts/comparing-folder-content)
