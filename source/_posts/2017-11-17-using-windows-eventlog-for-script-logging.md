---
layout: post
date: 2017-11-17 00:00:00
title: "PowerShell 技能连载 -用 Windows 事件日志记录脚本日志"
description: PowerTip of the Day - Using Windows EventLog for Script Logging
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
使用内置的 Windows 事件日志架构来记录脚本日志是很棒的方法，而且非常简单。以下是准备日志记录的初始步骤（需要管理员特权）：

```powershell
#requires -runasadministrator

New-EventLog -LogName PSScriptLog -Source Logon, Installation, Misc, Secret
Limit-EventLog -LogName PSScriptLog -MaximumSize 10MB -OverflowAction OverwriteAsNeeded
```

您可能需要改变日志的名称以及（或）错误源的名称。如果名字没有被占用，这些源可以起任意名称。

现在，每个普通用户可以使用以下代码来写入新的事件日志：

```powershell
Write-EventLog -LogName PSScriptLog -Source Logon -EntryType Warning -EventId 123 -Message "Problem in script $PSCommandPath"
```

请注意 `Write-EventLog` 使用和前面定义相同的 logfile，并且 source 名称必须是前面定义过的之一。

但脚本写入信息到日志文件后，您可以搜索日志或者用 `Get-EventLog` 创建报告：

```powershell
PS C:\> Get-EventLog -LogName PSScriptLog -EntryType Error -Message *test.ps1*
```

<!--more-->
本文国际来源：[Using Windows EventLog for Script Logging](http://community.idera.com/powershell/powertips/b/tips/posts/using-windows-eventlog-for-script-logging)
