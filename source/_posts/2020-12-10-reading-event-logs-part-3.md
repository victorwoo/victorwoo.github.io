---
layout: post
date: 2020-12-10 00:00:00
title: "PowerShell 技能连载 - 读取事件日志（第 3 部分）"
description: PowerTip of the Day - Reading Event Logs (Part 3)
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

与 `Win-EventLog` 相比，`Get-WinEvent` 的优点之一是它能够读取所有 Windows 事件日志，而不仅仅是经典事件日志。要找出这些其他事件日志的名称，请尝试以下操作：

```powershell
Get-WinEvent -ListLog * -ErrorAction Ignore |
    # ...that have records...
    Where-Object RecordCount -gt 0 |
    Sort-Object -Property RecordCount -Descending
```

这将返回系统上所有包含数据的事件日志的列表，并按记录的事件数进行排序。显然，诸如“系统”和“应用程序”之类的“经典”日志比较显眼，但是还有许多其他有价值的日志，例如“具有高级安全性/防火墙的 Microsoft-Windows-Windows 防火墙”。让我们检查其内容：

```powershell
Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-Windows Firewall With Advanced Security/Firewall'
    } -MaxEvents 20
```

由于我的系统正在使用内置防火墙，因此结果将返回有关更改防火墙规则和其他配置历史记录的详细信息。

使用不推荐使用的 `Get-EventLog` 将无法获得此信息。

<!--本文国际来源：[Reading Event Logs (Part 3)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/reading-event-logs-part-3)-->

