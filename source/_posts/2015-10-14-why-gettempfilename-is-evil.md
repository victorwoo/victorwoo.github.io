layout: post
date: 2015-10-14 11:00:00
title: "PowerShell 技能连载 - 为什么 GetTempFileName() 是有害的"
description: PowerTip of the Day - Why GetTempFileName() is Evil
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
有些人可能会用 .NET 方法来试图生成一个随机的临时文件名：

    $path = [System.IO.Path]::GetTempFileName()
    $path

它确实可以用。不过它还做了些别的事情。它实际上用那个文件名创建了一个空白文件：

    PS C:\> Test-Path $path
    True

如果您没有清除临时文件，将会在创建了 65535 个临时文件之后得到一个异常。

在 PowerShell 5.0 中，`New-TemporaryFile` 做了相同的事情，但是它返回了一个文件，这样您可以立即确认确实创建了一个文件，而不是一个文件名。

<!--more-->
本文国际来源：[Why GetTempFileName() is Evil](http://community.idera.com/powershell/powertips/b/tips/posts/why-gettempfilename-is-evil)
