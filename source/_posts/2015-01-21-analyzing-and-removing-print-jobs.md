layout: post
date: 2015-01-21 12:00:00
title: "PowerShell 技能连载 - 分析并移除打印任务"
description: PowerTip of the Day - Analyzing and Removing Print Jobs
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
_适用于 Windows 8.1 或 Server 2012 R2_

Windows 8.1 和 Server 2012 R2 引入了一个名为“PrintManagement”的模块。它包含了管理本地和远程打印机所需的所有 cmdlet。

在前一个技能中我们演示了如何读取打印任务。每个打印任务都有一个 `JobStatus` 属性告诉您该 `PrintJob` 是否成功完成。

可以通过这种方式获取所有的状态码：

    PS> Import-Module PrintManagement
     
    PS> [Microsoft.PowerShell.Cmdletization.GeneratedTypes.PrintJob.JobStatus]::GetNames([Microsoft.PowerShell.Cmdletization.GeneratedTypes.PrintJob.JobStatus])
    Normal
    Paused
    Error
    Deleting
    Spooling
    Printing
    Offline
    PaperOut
    Printed
    Deleted
    Blocked
    UserIntervention
    Restarted
    Complete
    Retained
    RenderingLocally

接下来，您可以过滤已有的打印任务。并且，比如打印出所有已完成或有错误的打印任务。这段代码将列出所有有错误或已完成的打印任务：

    $ComputerName = $env:COMPUTERNAME
    
    Get-Printer -ComputerName $ComputerName |  ForEach-Object { 
      Get-PrintJob -PrinterName $_.Name -ComputerName $ComputerName |
        Where-Object { $_.JobStatus -eq 'Complete' -or $_.JobStatus -eq 'Error' -or $_.JobStatus -eq 'Printed'}
     } 

要移除这些打印任务，只需要加上 `Remove-PrintJob` 命令：

    $ComputerName = $env:COMPUTERNAME
    
    Get-Printer -ComputerName $ComputerName |  ForEach-Object { 
      Get-PrintJob -PrinterName $_.Name -ComputerName $ComputerName |
        Where-Object { $_.JobStatus -eq 'Complete' -or $_.JobStatus -eq 'Error' -or $_.JobStatus -eq 'Printed'}
     } |
     Remove-PrintJob -CimSession $ComputerName

<!--more-->
本文国际来源：[Analyzing and Removing Print Jobs](http://community.idera.com/powershell/powertips/b/tips/posts/analyzing-and-removing-print-jobs)
