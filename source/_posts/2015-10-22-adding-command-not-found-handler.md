layout: post
date: 2015-10-22 11:00:00
title: "PowerShell 技能连载 - 增加“命令未找到”处理器"
description: PowerTip of the Day - Adding Command Not Found Handler
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
当 PowerShell 遇到一个未知的命令名时，您会见到一条红色的信息。

然而，从 PowerShell 3.0 开始，引入了一个“CommandNotFoundHandler”功能，可以在程序中使用。它可以记录信息，或者尝试解决问题。

这是一个简单的例子。当您运行这段代码后，无论何时遇到一个 PowerShell 不知道的命令，它会运行 `Show-Command` 并用合法的命令打开一个帮助工具：

    $ExecutionContext.InvokeCommand.CommandNotFoundAction =
    {
      param(
        [string]
        $commandName,
    
        [System.Management.Automation.CommandLookupEventArgs]
        $eventArgs
      )
    
      Write-Warning "Command $commandName was not found. Opening LookilookiTool."
      $eventArgs.CommandScriptBlock = { Show-Command }
    
    }

<!--more-->
本文国际来源：[Adding Command Not Found Handler](http://community.idera.com/powershell/powertips/b/tips/posts/adding-command-not-found-handler)
