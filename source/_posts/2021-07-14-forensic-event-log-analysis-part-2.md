---
layout: post
date: 2021-07-14 00:00:00
title: "PowerShell 技能连载 - 取证事件日志分析（第 2 部分）"
description: PowerTip of the Day - Forensic Event Log Analysis (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技能中，我们查看了 `Get-EventLog` 以进行取证分析并在应用程序日志中查找与搜索相关的错误。`Get-EventLog` 使用简单，但速度慢且已弃用。虽然在 Windows PowerShell 上使用 `Get-EventLog` 是完全可以的，但您可能希望改用 `Get-WinEvent`。它速度更快，也可以在 PowerShell 7 上运行。

让我们快速将 `Get-EventLog` 转换为 `Get-WinEvent`，以进行上一技巧中介绍的取证分析。下面的代码在应用程序事件日志中查找与“搜索”源相关的所有错误（您的系统上可能没有）：

```powershell
# old
Get-EventLog -LogName Application -Source *search* -EntryType error -Newest 10 | Select-Object TimeGenerated, Message

# new
Get-WinEvent -FilterHashtable @{
    LogName = 'Application'
    ProviderName = '*search*'
    Level = 1,2
} -ErrorAction Ignore | Select-Object TimeCreated, Message
```

要将每天的事件分组，请使用 `Group-Object` 和日期作为分组标准：

```powershell
# old
Get-EventLog -LogName Application -Source *search* -EntryType error | Group-Object { Get-Date $_.timegenerated -format yyyy-MM-dd } -NoElement


# new
Get-WinEvent -FilterHashtable @{
    LogName = 'Application'
    ProviderName = '*search*'
    Level = 1,2
} -ErrorAction Ignore | Group-Object { Get-Date $_.TimeCreated -format yyyy-MM-dd } -NoElement
```

同样，您的日志中可能没有任何与搜索相关的错误条目，但是当您调整条件并搜索不同的事件日志条目时，您会很快意识到 `Get-WinEvent` 的速度有多快。在上面的示例中，`Get-WinEvent` 比 `Get-EventLog` 快大约 10 倍。

<!--本文国际来源：[Forensic Event Log Analysis (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/forensic-event-log-analysis-part-2)-->

