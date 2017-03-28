layout: post
date: 2015-08-24 11:00:00
title: "PowerShell 技能连载 - 查找驱动器号"
description: PowerTip of the Day - Finding Drive Letters
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
以下是一个查找保留驱动器号的简单函数：

    #requires -Version 3
    
    function Get-DriveLetter
    {
        (Get-WmiObject -Class Win32_LogicalDisk).DeviceID
    }

要列出所有正在使用的驱动器号，请使用以下代码：

    PS> Get-DriveLetter
    C:
    D:
    Y:
    Z:
    
    PS>

要查看某个给定的驱动器号是否被保留，可以使用这段代码：

    PS> $letters = Get-DriveLetter
    
    PS> $letters -contains 'c:'
    True
    
    PS> $letters -contains 'f:'
    False
    
    PS>

<!--more-->
本文国际来源：[Finding Drive Letters](http://community.idera.com/powershell/powertips/b/tips/posts/finding-drive-letters)
