layout: post
date: 2014-09-08 11:00:00
title: "PowerShell 技能连载 - 快速处理路径"
description: PowerTip of the Day - Useful Path Manipulation Shortcuts
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
_适用于 PowerShell 所有版本_

以下是一系列有用的（并且易用的）用于处理文件路径的系统函数：

    [System.IO.Path]::GetFileNameWithoutExtension('file.ps1')
    [System.IO.Path]::GetExtension('file.ps1')
    [System.IO.Path]::ChangeExtension('file.ps1', '.copy.ps1')
    
    [System.IO.Path]::GetFileNameWithoutExtension('c:\test\file.ps1')
    [System.IO.Path]::GetExtension('c:\test\file.ps1')
    [System.IO.Path]::ChangeExtension('c:\test\file.ps1', '.bak')

所有这些方法都能接受文件名称或完整路径参数、能返回路径的不同部分，或改变其中的部分，例如扩展名。

<!--more-->
本文国际来源：[Useful Path Manipulation Shortcuts](http://community.idera.com/powershell/powertips/b/tips/posts/useful-path-manipulation-shortcuts)
