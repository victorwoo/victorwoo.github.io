layout: post
date: 2015-04-08 11:00:00
title: "PowerShell 技能连载 - 查找所有活动的驱动器号"
description: 'PowerTip of the Day - Find All Active Drive Letters '
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
要快速地获取所有驱动器号，请使用以下代码：

    #requires -Version 1
    
    [Environment]::GetLogicalDrives()

执行结果是所有活动的驱动器号：

    PS>
    C:\
    D:\
    E:\
    F:\
    G:\

<!--more-->
本文国际来源：[Find All Active Drive Letters ](http://powershell.com/cs/blogs/tips/archive/2015/04/08/find-all-active-drive-letters.aspx)
