layout: post
title: "PowerShell 技能连载 - 高效运行后台任务"
date: 2014-04-14 00:00:00
description: PowerTip of the Day - Running Background Jobs Efficiently
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
如前一个技巧所述，用后台任务来同步运行任务往往效率不高。当后台任务返回的数据量增加时，它的执行性能变得更差。

一个更高效的办法是用进程内任务。它们在同一个 PowerShell 实例内部的不同线程中独立运行，所以不需要将返回值序列化。

以下是一个用 PowerShell 线程功能，运行两个后台线程和一个前台线程的例子。为了使任务真正长时间运行，我们为每个任务在业务代码之外使用了 `Start-Sleep` 命令：

    $start = Get-Date
    
    $task1 = { Start-Sleep -Seconds 4; Get-Service }
    $task2 = { Start-Sleep -Seconds 5; Get-Service }
    $task3 = { Start-Sleep -Seconds 3; Get-Service }
    
    # run 2 in separate threads, 1 in the foreground
    $thread1 = [PowerShell]::Create()
    $job1 = $thread1.AddScript($task1).BeginInvoke()
    
    $thread2 = [PowerShell]::Create()
    $job2 = $thread2.AddScript($task2).BeginInvoke()
      
    $result3 = Invoke-Command -ScriptBlock $task3
    
    do { Start-Sleep -Milliseconds 100 } until ($job1.IsCompleted -and $job2.IsCompleted)
    
    $result1 = $thread1.EndInvoke($job1)
    $result2 = $thread2.EndInvoke($job2)
    
    $thread1.Runspace.Close()
    $thread1.Dispose()
    
    $thread2.Runspace.Close()
    $thread2.Dispose()
    
    $end = Get-Date
    Write-Host -ForegroundColor Red ($end - $start).TotalSeconds
    
如果依次执行这三个任务，分别执行 `Start-Sleep` 语句将至少消耗 12 秒。事实上该脚本只消耗 5 秒多一点。处理结果分别为 `$result1`，`$result2` 和 `$result3`。相对后台任务而言，返回大量数据基本不会造成时间消耗。

<!--more-->
本文国际来源：[Running Background Jobs Efficiently](http://community.idera.com/powershell/powertips/b/tips/posts/running-background-jobs-efficiently)
