layout: post
date: 2015-09-25 11:00:00
title: "PowerShell 技能连载 - 使用后台任务"
description: PowerTip of the Day - Using Background Jobs
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
后台任务可以用来加速您的脚本。如果您的脚本有一系列可并发执行的独立的任务组成，那么就合适使用后台任务。

后台任务适用于这两种情况：

- 任务需要至少 3-4 秒执行时间。
- 任务并不会返回大量数据。

以下是一个基本的由 3 个任务组成的后台任务场景。如果依次执行，它们一共约耗费 23 秒时间。通过使用后台任务，它们只消耗 11 秒（由最长的单个任务时间决定）加上一些额外的上下文时间。

    #requires -Version 2 
    
    # three things you want to do in parallel
    # for illustration, Start-Sleep is used
    # remove Start-Sleep and replace with real-world
    # tasks
    $task1 = { 
        Start-Sleep -Seconds 4 
        dir $home
        }
        
    $task2 = { 
        Start-Sleep -Seconds 8 
        Get-Service
    }
    $task3 = { 
        Start-Sleep -Seconds 11
        'Hello Dude'
     }
    
    $job1 = Start-Job -ScriptBlock $task1
    $job2 = Start-Job -ScriptBlock $task2
    
    $result3 = & $task3
    
    Wait-Job -Job $job1, $job2
    
    $result1 = Receive-Job -Job $job1
    $result2 = Receive-Job -Job $job2
    
    Remove-Job $job1, $job2

<!--more-->
本文国际来源：[Using Background Jobs](http://community.idera.com/powershell/powertips/b/tips/posts/using-background-jobs)
