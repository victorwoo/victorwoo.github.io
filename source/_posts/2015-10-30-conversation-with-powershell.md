---
layout: post
date: 2015-10-30 11:00:00
title: "PowerShell 技能连载 - 和 Powershell 对话"
description: PowerTip of the Day - Conversation with PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
今日的技能是当您键入一个未知的命令时，使用可编程的 `CommandNotFoundHandler` 让 PowerShell 和您对话：

    $ExecutionContext.InvokeCommand.CommandNotFoundAction =
    {
      param(
        [string]
        $commandName,

        [System.Management.Automation.CommandLookupEventArgs]
        $eventArgs
      )

      $Sapi = New-Object -ComObject Sapi.SpVoice
      $null = $Sapi.Speak("I don't know $commandName, stupid.")
    }

当您运行这段代码（并且打开您的声音）后，当用户输入一个未知的命令时，PowerShell 将会开口说话，并且抱怨它不知道您的命令。您可能会听到该声音两次：如果该命令不以 "`get-`" 开头，PowerShell 首先会试图查找一个以 "`get-`" 开头，并以您键入的名字结尾的命令。

<!--本文国际来源：[Conversation with PowerShell](http://community.idera.com/powershell/powertips/b/tips/posts/conversation-with-powershell)-->
