---
layout: post
title: "PowerShell 技能连载 - 从多个事件日志中获取错误事件"
date: 2013-12-30 00:00:00
description: PowerTip of the Day - Getting Error Events from Multiple Event Logs
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`Get-EventLog` 命令每次只能读取一个事件日志。然而如果您希望从多个事件日志中读取事件，您可以传入数组信息：

	$events = @(Get-EventLog -LogName System -EntryType Error)
	$events += Get-EventLog -LogName Application -EntryType Error

	$events

在这些例子中，使用 WMI 来查询可能会更简单一些——它可以一次性查询任意多个系统日志。

以下代码将从应用程序和系统日志中获取前 100 条错误日志（指的是总计 100 条，所以如果前 100 条错误都是应用程序日志，则当然不会包括系统错误）：

	Get-WmiObject -Class Win32_NTLogEvent -Filter 'Type="Error" and (LogFile="System" or LogFile="Application")' |
	  Select-Object -First 100 -Property TimeGenerated, LogFile, EventCode, Message

当您将 `Get-WmiObject` 换成 `Get-CimInstance`（PowerShell 3.0 新增的命令），那么诡异的 WMI 日期格式将会被自动转换为普通的日期和时间：

	Get-CimInstance -Class Win32_NTLogEvent -Filter 'Type="Error" and (LogFile="System" or LogFile="Application")' |
	  Select-Object -First 100 -Property TimeGenerated, LogFile, EventCode, Message

<!--本文国际来源：[Getting Error Events from Multiple Event Logs](http://community.idera.com/powershell/powertips/b/tips/posts/getting-error-events-from-multiple-event-logs)-->
