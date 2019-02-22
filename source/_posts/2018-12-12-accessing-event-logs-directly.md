---
layout: post
date: 2018-12-12 00:00:00
title: "PowerShell 技能连载 - 直接存取事件日志"
description: PowerTip of the Day - Accessing Event Logs Directly
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
通过 `Get-EventLog` 命令，您可以轻松地转储任意给定的事件日志内容，然而，如果您希望直接存取某个指定的事件日志，您只能使用 `-List` 参数来完全转储它们，然后选择其中一个您所关注的：

```powershell
$SystemLog = Get-EventLog -List | Where-Object { $_.Log -eq 'System' }
$SystemLog
```

一个更简单的方式是使用强制类型转换，类似这样：

```powershell
$systemLogDirect = [System.Diagnostics.EventLog]'System'
$systemLogDirect
```

Simply “convert” the event log name into an object of “EventLog” type. The result looks similar to this and provides information about the number of entries and the log file size:
只需要将时间日志名称“转换”为一个 "`EventLog`" 类型的对象。结果类似这样，并且提供了条目的数量和日志文件尺寸等信息：

```powershell
PS> $systemLogDirect

  Max(K) Retain OverflowAction        Entries Log
  ------ ------ --------------        ------- ---
  20.480      0 OverwriteAsNeeded      19.806 System
```

<!--本文国际来源：[Accessing Event Logs Directly](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/accessing-event-logs-directly)-->
