layout: post
title: "PowerShell 技能连载 - PowerShell 中的并行处理"
date: 2014-04-11 00:00:00
description: PowerTip of the Day - Parallel Processing in PowerShell
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
如果想提升一个脚本的执行速度，您也许会发现后台任务十分有用。它们适用于做大量并发处理的脚本。

PowerShell 是单线程的，一个时间只能处理一件事。使用后台任务时，后台会创建额外的 PowerShell 进程并且共享负荷。这只在任务彼此独立，并且后台任务不产生很多数据的情况下能很好地工作。从后台任务中发回数据是一个开销很大的过程，并且很有可能把节省出来的时间给消耗了，导致脚本执行起来反而更慢。

以下是三个可以并发执行的任务：

    $start = Get-Date
    
    # get all hotfixes
    $task1 = { Get-Hotfix }
    
    # get all scripts in your profile
    $task2 = { Get-Service | Where-Object Status -eq Running }
    
    # parse log file
    $task3 = { Get-Content -Path $env:windir\windowsupdate.log | Where-Object { $_ -like '*successfully installed*' } }
    
    # run 2 tasks in the background, and 1 in the foreground task
    $job1 =  Start-Job -ScriptBlock $task1 
    $job2 =  Start-Job -ScriptBlock $task2 
    $result3 = Invoke-Command -ScriptBlock $task3
    
    # wait for the remaining tasks to complete (if not done yet)
    $null = Wait-Job -Job $job1, $job2
    
    # now they are done, get the results
    $result1 = Receive-Job -Job $job1
    $result2 = Receive-Job -Job $job2
    
    # discard the jobs
    Remove-Job -Job $job1, $job2
    
    $end = Get-Date
    Write-Host -ForegroundColor Red ($end - $start).TotalSeconds

在一个测试环境中，执行所有三个任务消耗 5.9 秒。三个任务的结果分别保存到 $result1，$result2，$result3。

我们测试一下三个任务在前台顺序执行所消耗的时间：

    $start = Get-Date
    
    # get all hotfixes
    $task1 = { Get-Hotfix }
    
    # get all scripts in your profile
    $task2 = { Get-Service | Where-Object Status -eq Running }
    
    # parse log file
    $task3 = { Get-Content -Path $env:windir\windowsupdate.log | Where-Object { $_ -like '*successfully installed*' } }
    
    # run them all in the foreground:
    $result1 = Invoke-Command -ScriptBlock $task1 
    $result2 = Invoke-Command -ScriptBlock $task2 
    $result3 = Invoke-Command -ScriptBlock $task3
    
    $end = Get-Date
    Write-Host -ForegroundColor Red ($end - $start).TotalSeconds

这段代码仅仅执行了 5.05 秒。所以后台任务只对于长期运行并且各自占用差不多时间的任务比较有效。由于这三个测试任务返回了大量的数据，所以并发执行带来的好处差不多被将执行结果序列化并传回前台进程的过程给抵消掉了。

<!--more-->
本文国际来源：[Parallel Processing in PowerShell](http://community.idera.com/powershell/powertips/b/tips/posts/parallel-processing-in-powershell)
