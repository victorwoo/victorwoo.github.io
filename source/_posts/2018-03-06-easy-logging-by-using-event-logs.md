---
layout: post
date: 2018-03-06 00:00:00
title: "PowerShell 技能连载 - 使用事件日志方便地记录日志"
description: PowerTip of the Day - Easy Logging by Using Event Logs
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
脚本常常需要记录它们做了什么，并且 PowerShell 脚本开发者们需要做投入许多时间精力来将信息记录到文本文件中。

作为另一个选择，您可以方便地使用 Microsoft 已投入建设的工作：PowerShell 可以使用事件日志系统来记录信息。要做测试实验，请用以下代码创建一个新的事件日志。这部分需要管理员特权（写日志时不需要）：

```powershell
#requires -RunAsAdministrator

# name for your log
$LogName = 'PowerShellPrivateLog'
# size (must be dividable by 64KB)
$Size = 10MB

# specify a list of names that you'd use as source for your events
$SourceNames = 'Logon','Work','Misc','Test','Debug'

New-EventLog -LogName $LogName -Source $SourceNames
Limit-EventLog -LogName $LogName -MaximumSize $Size -OverflowAction OverwriteAsNeeded
```

当日志创建了以后，任何用户都可以记录日志文件：

```powershell
PS> Write-EventLog -LogName PowerShellPrivateLog -Message 'Script Started' -Source Work -EntryType Information -EventId 1

PS> Write-EventLog -LogName PowerShellPrivateLog -Message 'Something went wrong!' -Source Work -EntryType Error -EventId 1



PS> Get-EventLog -LogName PowerShellPrivateLog | ft -AutoSize

Index Time         EntryType   Source InstanceID Message              
----- ----         ---------   ------ ---------- -------              
    2 Jan 30 21:57 Error       Work            1 Something went wrong!
    1 Jan 30 21:57 Information Work            1 Script Started 
```

当您创建日志时，必须指定一个合法的 `-Source` 名称。使用这项技术的一个好处是您可以用 `Get-EventLog` 来方便地分析您的日志记录。

<!--more-->
本文国际来源：[Easy Logging by Using Event Logs](http://community.idera.com/powershell/powertips/b/tips/posts/easy-logging-by-using-event-logs)
