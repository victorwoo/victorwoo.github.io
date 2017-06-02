---
layout: post
title: "PowerShell 技能连载 - 从所有事件日志中获取全部事件"
date: 2014-04-15 00:00:00
description: PowerTip of the Day - Getting Events From All Event Logs
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
最近，一个读者咨询如何从所有事件日志中获取全部事件，并且能将它们保存到文件中。

以下是一个可能的解决方案：

    # calculate start time (one hour before now)
    $Start = (Get-Date) - (New-Timespan -Hours 1)
    $Computername = $env:COMPUTERNAME 
     
    # Getting all event logs
    Get-EventLog -AsString -ComputerName $Computername |
      ForEach-Object {
        # write status info
        Write-Progress -Activity "Checking Eventlogs on \\$ComputerName" -Status $_
    
        # get event entries and add the name of the log this came from
        Get-EventLog -LogName $_ -EntryType Error, Warning -After $Start -ComputerName $ComputerName -ErrorAction SilentlyContinue |
          Add-Member NoteProperty EventLog $_ -PassThru 
           
      } |
      # sort descending
      Sort-Object -Property TimeGenerated -Descending |
      # select the properties for the report
      Select-Object EventLog, TimeGenerated, EntryType, Source, Message | 
      # output into grid view window
      Out-GridView -Title "All Errors & Warnings from \\$Computername" 
    
在这个脚本的顶部，您可以设置希望查询的远程主机，以及希望获取的最近小时数。

接下来，这个脚本获取该机器上所有可用的日志文件，然后用一个循环来获取指定时间区间中的错误和警告记录。要想知道哪个事件是来自哪个日志文件，脚本还用 `Add-Member` 为日志记录添加了一个新的“EventLog”属性。

脚本的执行结果是在一个网格视图的窗口中显示一小时之内的所有错误和警告事件。如果将 `Out-GridView` 改为 `Out-File` 或 `Export-Csv` 将可以把信息保存到磁盘。

请注意远程操作需要 Administrator 特权。远程操作可能需要额外的安全设置。另外，请注意如果以非 Administrator 身份运行该代码，将会收到红色的错误提示信息（因为某些日志，比如说“安全”需要特殊的操作权限）。

<!--more-->
本文国际来源：[Getting Events From All Event Logs](http://community.idera.com/powershell/powertips/b/tips/posts/getting-events-from-all-event-logs)
