---
layout: post
date: 2021-02-18 00:00:00
title: "PowerShell 技能连载 - Cross-Platform Out-GridView"
description: PowerTip of the Day - Cross-Platform Out-GridView
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Out-GridView is one of the most frequently used cmdlets and opens a general purpose selection dialog. Unfortunately, PowerShell can display graphical elements such as windows only on the Windows operating system. On Linux and macOS, graphical cmdlets such as Out-GridView are not available.

You may want to try the new text-based Out-ConsoleGridView instead. This cmdlet is available only for PowerShell 7 (it won’t work in Windows PowerShell). Install it like this:

    Install-Module -Name Microsoft.PowerShell.ConsoleGuiTools -Scope CurrentUser


Once installed, in many cases you can now easily replace Out-GridView with Out-ConsoleGridView and enjoy a text-based selection dialog much similar to the good old Norton Commander. Here is a legacy Windows PowerShell script that wouldn’t work on Linux:

    Get-Process |
    Where-Object MainWindowHandle |
    Select-Object -Property Name, Id, Description |
    Sort-Object -Property Name |
    Out-GridView -Title 'Prozesse' -OutputMode Multiple |
    Stop-Process -WhatIf


Simply replace Out-GridView with Out-ConsoleGridView, and you are all set.





<!--本文国际来源：[Cross-Platform Out-GridView](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/cross-platform-out-gridview)-->

