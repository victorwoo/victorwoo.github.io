layout: post
date: 2016-02-15 12:00:00
title: "PowerShell 技能连载 - ___"
description: PowerTip of the Day - Who Is Listening? (Part 1)
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
The good oldfashioned netstat.exe can tell you the ports that applications listen on. The result is plain-text, though. PowerShell can use regular expressions though to split the text into CSV data, and ConvertFrom-Csv can then turn the text into real objects.

This is just an example of how PowerShell can use even the most basic data:

    #requires -Version 2
    NETSTAT.EXE -anop tcp| 
    Select-Object -Skip  4|
    ForEach-Object -Process {
      [regex]::replace($_.trim(),'\s+',' ')
    }|
    ConvertFrom-Csv -d ' ' -Header 'proto', 'src', 'dst', 'state', 'pid'|
    Select-Object -Property src, state, @{
      name = 'process'
      expression = {
        (Get-Process -PipelineVariable $_.pid).name
      }
    } |
    Format-List
    

The result may look similar to this:

      
    src     : 0.0.0.0:135
    state   : LISTEN
    process : {Adobe CEF Helper, Adobe CEF Helper, Adobe Desktop Service, 
              AdobeIPCBroker...}
    
    src     : 0.0.0.0:445
    state   : LISTEN
    process : {Adobe CEF Helper, Adobe CEF Helper, Adobe Desktop Service, 
              AdobeIPCBroker...}
    
    src     : 0.0.0.0:5985
    state   : LISTEN
    process : {Adobe CEF Helper, Adobe CEF Helper, Adobe Desktop Service, 
              AdobeIPCBroker...}
    
    src     : 0.0.0.0:7680
    state   : LISTEN
    process : {Adobe CEF Helper, Adobe CEF Helper, Adobe Desktop Service, 
              AdobeIPCBroker...}
    
    src     : 0.0.0.0:7779
    state   : LISTEN
    process : {Adobe CEF Helper, Adobe CEF Helper, Adobe Desktop Service, 
              AdobeIPCBroker...}

<!--more-->
本文国际来源：[Who Is Listening? (Part 1)](http://powershell.com/cs/blogs/tips/archive/2016/02/15/who-is-listening-part-1.aspx)
