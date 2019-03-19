---
layout: post
date: 2018-06-22 00:00:00
title: "PowerShell 技能连载 - 理解脚本块日志（第 1 部分）"
description: PowerTip of the Day - Understanding Script Block Logging (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
从 PowerShell 5 开始，PowerShell 引擎开始记录执行的命令和脚本块。缺省情况下，只有被认为有潜在威胁的命令会记录日志。当启用了详细日志后，由所有用户执行的所有执行代码都会被记录。

这是一个介绍脚本块日志的迷你系列的第一部分。今天，我们只是学习以最基础的方式使用脚本块日志。一行代码就够了：

```powershell
$logInfo = @{ ProviderName="Microsoft-Windows-PowerShell"; Id = 4104 }

Get-WinEvent -FilterHashtable $logInfo |
    Select-Object -ExpandProperty Message
```

这将从 "Microsoft-Windows-PowerShell" 的日志（它包含代码日志）中读取所有 ID 为 4104 的事件。请注意 PowerShell Core 也记录日志，但是使用的是一个不同的日志文件。

您现在可以类似这样获取大量的数据：

    Creating Scriptblock text (1 of 1):
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass

    ScriptBlock ID: aeb85bcb-98be-42d0-b695-fbbb975ec5d2
    Path:


如果 `Path` 为空，则说明该命令以交互的方式执行。否则，在这里可以查看到脚本的路径。

如果您没有获取到任何信息，请考虑以下可能性：

* 您是否使用的是 Windows PowerShell？如果您使用的是 PowerShell Core，您需要调整日志文件名。
* 缺省情况下，脚本块日志仅记录和安全有关的代码。如果您没有涉及到这方面的代码，可能不会收到任何记录。

以下代码是和安全相关的，当您执行它时，您将会从后续的日志中读取到这行代码：

```powershell
PS> Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
```

<!--本文国际来源：[Understanding Script Block Logging (Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/understanding-script-block-logging-part-1)-->
