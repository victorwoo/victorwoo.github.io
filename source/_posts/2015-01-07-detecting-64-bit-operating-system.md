layout: post
date: 2015-01-07 12:00:00
title: "PowerShell 技能连载 - 检测 64 位操作系统"
description: PowerTip of the Day - Detecting 64-bit Operating System
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
_适用于 Windows 7/Server 2008 R2_

要检测一个脚本是运行在 32 位环境还是 64 位环境是十分简单的：只需要检查指针的大小，看是等于 4 字节还是 8 字节：

    if ([IntPtr]::Size -eq 8)
    {
        '64-bit'
    }
    else
    {
        '32-bit'
    } 

不过这并不会告诉您操作系统的类型。这是由于 PowerShell 脚本可以在 64 位机器中运行在 32 位进程里。

要检测 OS 类型，请试试这段代码：

    if ([Environment]::Is64BitOperatingSystem)
    {
        '64-bit'
    }
    else
    {
        '32-bit'
    } 

而且，`Environment` 类也可以检查您的进程类型：

    if ([Environment]::Is64BitProcess)
    {
        '64-bit'
    }
    else
    {
        '32-bit'
    }

<!--more-->
本文国际来源：[Detecting 64-bit Operating System](http://community.idera.com/powershell/powertips/b/tips/posts/detecting-64-bit-operating-system)
