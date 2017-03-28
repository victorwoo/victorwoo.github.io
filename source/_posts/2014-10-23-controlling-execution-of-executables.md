layout: post
date: 2014-10-23 11:00:00
title: "PowerShell 技能连载 - 控制可执行文件的执行"
description: PowerTip of the Day - Controlling Execution of Executables
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
_适用于 PowerShell 所有版本_

PowerShell 将所有可执行程序（扩展名为 EXE 的文件）视为普通的命令。您甚至可以限制 PowerShell 不能执行任何可执行程序或只能执行白名单内的程序。

缺省的设置是允许任何 EXE 执行：

    PS> $ExecutionContext.SessionState.Applications
    *

该设置为仅允许 `ping.exe` 和 `regedit.exe` 执行：

    $ExecutionContext.SessionState.Applications.Clear()
    $ExecutionContext.SessionState.Applications.Add('ping.exe')
    $ExecutionContext.SessionState.Applications.Add('regedit.exe')

以下是结果：

    PS> $ExecutionContext.SessionState.Applications
    ping.exe
    regedit.exe

显然地，您可以轻松地将设置恢复到缺省状态：

    PS> $ExecutionContext.SessionState.Applications.Add('*')
    
    PS> explorer
    
    PS>

所以，该设置可以使执行 EXE 程序变得更困难（或者说防止不小心运行了不该运行的 EXE）。若真要将它作为安全策略，您还需要关闭所谓的“语言模式”。

当语言模式关闭时，您无法直接存取 .NET 对象。这意味着您无法在当前的 PowerShell 会话中回退该操作。我们将在明天详细介绍语言模式设置。

<!--more-->
本文国际来源：[Controlling Execution of Executables](http://community.idera.com/powershell/powertips/b/tips/posts/controlling-execution-of-executables)
