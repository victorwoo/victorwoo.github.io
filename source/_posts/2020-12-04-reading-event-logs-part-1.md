---
layout: post
date: 2020-12-04 00:00:00
title: "PowerShell 技能连载 - 读取事件日志（第 1 部分）"
description: PowerTip of the Day - Reading Event Logs (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 Windows 中，有许多事件日志，例如“系统”和“应用程序”，在 Windows PowerShell 中，使用 `Get-EventLog` 从这些日志中检索事件条目很简单。这种单行代码从您的系统事件日志中返回最新的五个错误事件：

```powershell
PS> Get-EventLog -LogName System -EntryType Error -Newest 5 | Out-GridView
```

在 PowerShell 7 和更高版本中，cmdlet `Get-EventLog` 不再存在。它被使用不同语法的 `Get-WinEvent` 代替，并且查询条件以哈希表的形式传入：

```powershell
Get-WinEvent -FilterHashtable @{
  LogName = 'System'
  Level = 2
} -MaxEvents 5
```

“`Level`”键是一个数字值，值越小，事件越紧急。 ID 号 2 代表“错误”条目。 ID 号 3 将代表“警告”条目。要查看错误和警告，请提交一个数组：

```powershell
Get-WinEvent -FilterHashtable @{
  LogName = 'System'
  Level = 2,3
  } -MaxEvents 5
```

即使您正在使用 Windows PowerShell，并且不打算很快过渡到 PowerShell 7，现在还是该习惯于 `Get-WinEvent` 和弃用 `Get-EventLog` 的时候，因为新的 `Get-WinEvent` 自 PowerShell 3 起就可用，并确保您的代码也将在将来的 PowerShell 版本中无缝运行。

此外，`Get-WinEvent` 不仅可以访问一些经典的 Windows 事件日志，还可以访问所有特定于应用程序的事件。另外，与从 `Get-EventLog` 接收到的结果相比， `Get-WinEvent` 传递的结果更加完整：后者偶尔返回带有诸如“找不到事件 xyz 的描述”之类的消息的结果。`Get-WinEvent` 始终返回完整的消息。

<!--本文国际来源：[Reading Event Logs (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/reading-event-logs-part-1)-->

