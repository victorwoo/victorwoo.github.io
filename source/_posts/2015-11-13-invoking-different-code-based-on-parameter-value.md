---
layout: post
date: 2015-11-13 12:00:00
title: "PowerShell 技能连载 - 根据参数值执行不同的代码"
description: PowerTip of the Day - Invoking Different Code Based on Parameter Value
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
以下是一个使用一系列选项的操作参数的简单概念。每个选项对应一个将被执行的脚本块。

    #requires -Version 2
    function Invoke-SomeAction
    {
      param
      (
        [String]
        [Parameter(Mandatory=$true)]
        [ValidateSet('Deploy','Delete','Refresh')]
        $Action
      )
    
      $codeAction = @{}
      $codeAction.Deploy = { 'Doing the Deployment' }
      $codeAction.Delete = { 'Doing the Deletion' }
      $codeAction.Refresh = { 'Doing the Refresh' }
    
      & $codeAction.$Action
    
    }

当运行这段代码后，键入 `Invoke-SomeAction`，ISE 将会提供它所支持的“`Deployment`”、“`Deletion`”和“`Refresh`”操作。相对简单的 PowerShell 控制台至少会提供 action 参数的 tab 补全功能。

根据您的选择，PowerShell 将会执行合适的脚本块。如您所见，该操作脚本块可以包括任意代码，甚至多页代码。

<!--more-->
本文国际来源：[Invoking Different Code Based on Parameter Value](http://community.idera.com/powershell/powertips/b/tips/posts/invoking-different-code-based-on-parameter-value)
