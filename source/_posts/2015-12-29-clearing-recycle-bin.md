layout: post
date: 2015-12-29 12:00:00
title: "PowerShell 技能连载 - ___"
description: PowerTip of the Day - Clearing Recycle Bin
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
Before the advent of PowerShell 5.0, to clear the recycler, you would have to manually delete the content of the hidden $Recycle.Bin folder in the root of all drives that have a recycler.

Some authors recommended the use of a COM object called Shell.Application, too, which tends to be unreliable because the recycler may not be visible at all times, depending on your Explorer settings.

Fortunately, PowerShell 5.0 finally comes with a Clear-RecycleBin cmdlet.

<!--more-->
本文国际来源：[Clearing Recycle Bin](http://powershell.com/cs/blogs/tips/archive/2015/12/29/clearing-recycle-bin.aspx)
