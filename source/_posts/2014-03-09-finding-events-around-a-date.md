---
layout: post
title: "PowerShell 技能连载 - 查找一个时间点附近的日志"
date: 2014-03-09 00:00:00
description: PowerTip of the Day - Finding Events around A Date
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
经常地，您会需要浏览某个指定日期附近的所有系统事件。我们假设某台机器在 08:47 崩溃了，您需要查看该时间前后 2 分钟之内的事件。

以下是一个完成以上任务的脚本：

    $deltaminutes = 2
    $delta = New-TimeSpan -Minutes $deltaminutes

    $time = Read-Host -Prompt 'Enter time of event (yyyy-MM-dd HH:mm:ss or HH:mm)'

    $datetime = Get-Date -Date $time
    $start = $datetime - $delta
    $end = $datetime + $delta

    $result = @(Get-EventLog -LogName System -Before $end -After $start)
    $result += Get-EventLog -LogName Application -Before $end -After $start

    $result | Sort-Object -Property TimeGenerated -Descending |
      Out-GridView -Title "Events +/− $deltaminutes minutes around $datetime"

当您运行它时，它需要用户输入一个时间或日期 + 时间值。然后，您可以获得该时间点前后 2 分钟之内系统和应用程序日志中的所有事件。

![](/img/2014-03-09-finding-events-around-a-date-001.png)

如果您没有获取到任何数据，那么说明在这段时间段中没有任何事件。

这段代码示范了您可以获取一个时间段之内的事件，并且示范了如何查询多个事件日志。

<!--本文国际来源：[Finding Events around A Date](http://community.idera.com/powershell/powertips/b/tips/posts/finding-events-around-a-date)-->
