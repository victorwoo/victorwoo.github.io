layout: post
date: 2016-01-11 12:00:00
title: "PowerShell 技能连载 - ___"
description: PowerTip of the Day - Finding Current File System Path
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
PowerShell supports not just the file system, so you can set the current path to a different provider (Set-Location). Here is a trick that always gets you the current file system location no matter which provider is currently active:

     
    PS C:\> cd hkcu:\
    
    PS HKCU:\> $ExecutionContext.SessionState.Path
    
    CurrentLocation CurrentFileSystemLocation
    --------------- -------------------------
    HKCU:\          C:\                      
    
    
    
    PS HKCU:\> $ExecutionContext.SessionState.Path.CurrentFileSystemLocation
    
    Path
    ----
    C:\ 
    
    
    
    PS HKCU:\> $ExecutionContext.SessionState.Path.CurrentFileSystemLocation.Path
    C:\ 
     

Throughout this month, we'd like to point you to two awesome community-driven global PowerShell events taking place this year:

Europe: April 20-22: 3-day PowerShell Conference EU in Hannover, Germany, with more than 30+ speakers including Jeffrey Snover and Bruce Payette, and 60+ sessions ([www.psconf.eu](http://www.psconf.eu)).

Asia: October 21-22: 2-day PowerShell Conference Asia in Singapore. Watch latest annoncements at [www.psconf.asia](http://www.psconf.asia/)

Both events have limited seats available so you may want to register early.

<!--more-->
本文国际来源：[Finding Current File System Path](http://powershell.com/cs/blogs/tips/archive/2016/01/11/finding-current-file-system-path.aspx)
