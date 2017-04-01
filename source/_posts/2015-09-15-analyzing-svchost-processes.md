layout: post
date: 2015-09-15 11:00:00
title: "PowerShell 技能连载 - 分析 svchost 进程"
description: PowerTip of the Day - Analyzing svchost Processes
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
有时候，您会在任务管理器或 `Get-Process` 输出中看到一系列名为“svchost”的进程。每个“svchost”进程中运行着一个或多个 Windows 服务。

要更好地理解这些进程后隐藏着哪些服务，您可以使用这样的代码：

    #requires -Version 2
    # Hash table defines two keys: 
    # Name and Expression
    # they can be used with Select-Object
    # to produce "calculated" properties
    $Service = @{
      Name = 'Service'
      Expression = {
        # if the process is "svchost"...
        if ($_.Name -eq 'svchost')
        {
          # ...find out the current process ID...
          $processID = $_.ID
          # ...and look up the services attached to it
          ($serviceList.$processID).Name -join ', '
        }
      }
    }
    
    # create a service lookup table with ProcessID as a key
    $serviceList = Get-WmiObject -Class Win32_Service |
    Group-Object -Property ProcessID -AsString -AsHashTable
      
    # get all running processes...
    Get-Process |
    # add the new calculated column defined in $Service...
    Select-Object -Property Name, ID, CPU, $Service |
    # and output results to a grid view Window
    Out-GridView

当您运行这段代码时，您会见到当前运行中的进程列表。当进程名是“svchost”时，您会在新的“Service”列中查看到服务名。

<!--more-->
本文国际来源：[Analyzing svchost Processes](http://community.idera.com/powershell/powertips/b/tips/posts/analyzing-svchost-processes)
