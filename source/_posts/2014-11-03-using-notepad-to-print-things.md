layout: post
date: 2014-11-03 12:00:00
title: "PowerShell 技能连载 - 调用记事本打印文本"
description: PowerTip of the Day - Using Notepad to Print Things
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

若要调用记事本打印纯文本文件，请使用这行代码（请将路径替换成需要的值，否则将打印出长长的系统日志文件）：

    Start-Process -FilePath notepad -ArgumentList '/P C:\windows\WindowsUpdate.log'

<!--more-->
本文国际来源：[Using Notepad to Print Things](http://powershell.com/cs/blogs/tips/archive/2014/11/03/using-notepad-to-print-things.aspx)
