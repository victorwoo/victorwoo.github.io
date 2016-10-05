layout: post
date: 2014-07-30 11:00:00
title: "PowerShell 技能连载 - 修正 PowerShell 中的路径"
description: PowerTip of the Day - Correcting PowerShell Paths
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
_适用于所有 PowerShell 版本_

有些时候，您会为某些奇怪的路径格式感到困惑，比如这个：

    Microsoft.PowerShell.Core\FileSystem::C:\windows\explorer.exe

这是一个完整的 PowerShell 路径名，路径中包含了了模块名和提供器名。要得到一个纯的路径名，请使用以下代码：

    Convert-Path -Path Microsoft.PowerShell.Core\FileSystem::C:\windows\explorer.exe

<!--more-->
本文国际来源：[Correcting PowerShell Paths](http://community.idera.com/powershell/powertips/b/tips/posts/correcting-powershell-paths)
