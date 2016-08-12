layout: post
date: 2015-10-29 11:00:00
title: "PowerShell 技能连载 - 查看操作系统版本"
description: PowerTip of the Day - Finding Operating System Version
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
一个最简单的查看操作系统版本号的方法是这一行代码：

    PS> [Environment]::OSVersion
    
    Platform ServicePack        Version             VersionString         
    -------- -----------        -------             -------------         
     Win32NT Service Pack 1     6.1.7601.65536      Microsoft Windows N...

“`Environment`”类型提供了您计算机很多方面的信息。例如，操作系统核心的个数：

    PS> [Environment]::ProcessorCount
    4

要查看该类型能做什么，请在 PowerShell ISE 中，键入：

    [Environment]::

当您按下第二个冒号时，智能提示将打开一个菜单，里面包含了该类型的所有静态属性和方法。

<!--more-->
本文国际来源：[Finding Operating System Version](http://powershell.com/cs/blogs/tips/archive/2015/10/29/finding-operating-system-version.aspx)
