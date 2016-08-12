layout: post
date: 2015-06-22 11:00:00
title: "PowerShell 技能连载 - 分析（所有）事件日志源"
description: PowerTip of the Day - Analyzing (All) Event Log Entries
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
您也许知道 `Get-EventLog` 命令。该命令能从一个指定的系统日志中读取所有条目：

    Get-EventLog -LogName System

然而，`Get-EventLog` 一次只能查询一个事件日志源。所以如果您希望在所有事件日志源中查找所有错误信息，您需要创建一个循环，并且需要知道事件日志名字。

以下是一个单行的查询所有事件日志的简单技巧：

    Get-EventLog -List |
      Select-Object -ExpandProperty Entries -ErrorAction SilentlyContinue |
      Where-Object { $_.EntryType -eq 'Error' }

<!--more-->
本文国际来源：[Analyzing (All) Event Log Entries](http://powershell.com/cs/blogs/tips/archive/2015/06/22/analyzing-all-event-log-entries.aspx)
