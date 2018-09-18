---
layout: post
date: 2018-09-12 00:00:00
title: "PowerShell 技能连载 - 浏览所有的事件日志"
description: PowerTip of the Day - Browsing All Event Logs
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
`Get-EventLog` 总是需要您通过 `LogName` 明确地指定一个事件日志。您无法使用通配符，并且无法一次性浏览所有事件日志。

然而，可以使用这个技巧：

```powershell
PS> Get-EventLog -LogName *

  Max(K) Retain OverflowAction        Entries Log
  ------ ------ --------------        ------- ---
  20.480      0 OverwriteAsNeeded      13.283 Application
      512      7 OverwriteOlder             98 Dell
  20.480      0 OverwriteAsNeeded           0 HardwareEvents
      512      7 OverwriteOlder              0 Internet Explorer
      512      7 OverwriteOlder             46 isaAgentLog
  20.480      0 OverwriteAsNeeded           0 Key Management Service
      128      0 OverwriteAsNeeded          97 OAlerts
  10.240      0 OverwriteAsNeeded           0 PowerShellPrivateLog
      512      7 OverwriteOlder              0 PreEmptive
                                              Security
  20.480      0 OverwriteAsNeeded       5.237 System
  16.384      0 OverwriteAsNeeded          20 TechSmith
  15.360      0 OverwriteAsNeeded      10.279 Windows PowerShell
```

所以显然，`-LogName` 终究不支持通配符。然而，您现在看到的不再是事件日志项，而是一个摘要视图。不过您仍然可以访问以下的事件日志条目：

```powershell
PS> Get-EventLog -LogName * | Select-Object -ExpandProperty Entries -ErrorAction SilentlyContinue
```

这将从所有的日志中转储所有事件日志条目。在这儿，您可以添加自定义过滤器。要查看近 48 小时所有事件日志错误，请试试这段代码：

```powershell
# take events not older than 48 hours
$deadline = (Get-Date).AddHours(-48)

Get-EventLog -LogName * |
  ForEach-Object {
    # get the entries, and quiet errors
    try { $_.Entries } catch {}
  } |
  Where-Object {
    # take only errors
    $_.EntryType -eq 'Error'
  } |
  Where-Object {
    # take only entries younger than the deadline
    $_.TimeGenerated -gt $deadline
  }
```

<!--more-->
本文国际来源：[Browsing All Event Logs](http://community.idera.com/powershell/powertips/b/tips/posts/browsing-all-event-logs)
