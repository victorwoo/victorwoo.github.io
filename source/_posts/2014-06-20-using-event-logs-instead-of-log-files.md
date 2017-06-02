---
layout: post
title: "PowerShell 技能连载 - 用事件日志代替日志文件"
date: 2014-06-20 00:00:00
description: PowerTip of the Day - Using Event Logs Instead of Log Files
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
人们常常使用文件来记录日志。这样做并没有错，但是使用 Windows 内置的事件日志系统可能会简单得多。

如果您有管理员权限，您可以随时创建新的事件日志：

    New-EventLog -LogName myLog -Source JobDue, JobDone, Remark

这将创建一个名为“myLog”的新日志，它的来源为“JobDue”、“JobDone”和“Remark”。管理员权限只是用来创建事件日志用。剩下的操作任何普通用户都可以操作。现在您的日志可以记录到新的事件日志中。

    Write-EventLog -LogName myLog -Source JobDue -EntryType Information -EventId 1 -Message 'This could be a job description.'
    Write-EventLog -LogName myLog -Source JobDue -EntryType Information -EventId 1 -Message 'This could be another job description.'

通过 `Get-EventLog` 命令，您可以轻松地解析您的日志并且查找信息：

    Get-EventLog -LogName myLog -Source JobDue -After 2014-05-10

通过 `Limit-EventLog`，您还可以配置您的日志，限制最大大小。

<!--more-->
本文国际来源：[Using Event Logs Instead of Log Files](http://community.idera.com/powershell/powertips/b/tips/posts/using-event-logs-instead-of-log-files)
