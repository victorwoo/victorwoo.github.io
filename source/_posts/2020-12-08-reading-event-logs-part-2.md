---
layout: post
date: 2020-12-08 00:00:00
title: "PowerShell 技能连载 - 读取事件日志（第 2 部分）"
description: PowerTip of the Day - Reading Event Logs (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技能中，我们鼓励您弃用 `Get-EventLog` cmdlet，而开始使用 `Get-WinEvent`——因为后者功能更强大，并且在 PowerShell 7 中不再支持前者。

让我们再次练习如何将 `Get-EventLog` 语句转换为 `Get-WinEvent`。这是我想翻译的一行代码。它从过去 48 小时内发生的系统事件日志中返回所有错误和警告：

```powershell
$twoDaysAgo = (Get-Date).AddDays(-2)Get-EventLog -LogName System -EntryType Error, Warning -After $twoDaysAgo
```

这将是在所有 PowerShell 版本中均可使用的 `Get-WinEvent` 单行代码：

```powershell
$twoDaysAgo = (Get-Date).AddDays(-2)Get-WinEvent -FilterHashtable @{
  LogName = 'System'  Level = 2,3  StartTime = $twoDaysAgo  }
```

它返回相同的事件，但是速度更快。以下是您可以在哈希表中使用的其余键：

col 1         | col 2       | col 3
------------- | ----------- | ------------------
 Key name     |  Data Type  |  Wildcards Allowed
 LogName      |  <String[]> |  Yes
 ProviderName |  <String[]> |  Yes
 Path         |  <String[]> |  No
 Keywords     |  <Long[]>   |  No
 ID           |  <Int32[]>  |  No
 Level        |  <Int32[]>  |  No
 StartTime    |  <DateTime> |  No
 EndTime      |  <DataTime> |  No
 UserID       |  <SID>      |  No
 Data         |  <String[]> |  No

<!--本文国际来源：[Reading Event Logs (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/reading-event-logs-part-2)-->

