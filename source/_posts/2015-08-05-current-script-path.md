layout: post
date: 2015-08-05 11:00:00
title: "PowerShell 技能连载 - 当前脚本的路径"
description: PowerTip of the Day - Current Script Path
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
在 PowerShell 1.0 和 2.0 中，您需要一堆奇怪的代码来获得当前脚本的位置：

    # make sure the script is saved and NOT "Untitled"!
     
    $invocation = (Get-Variable MyInvocation).Value
    $scriptPath = Split-Path $invocation.MyCommand.Path
    $scriptName = $invocation.MyCommand.Name
    
    $scriptPath
    $scriptName

只有将它放在脚本的根部，这段代码才能用。

从 PowerShell 3.0 开始，事情变得更简单了，并且这些特殊变量在您脚本的任意地方都可以用。

    # make sure the script is saved and NOT "Untitled"!
    
    $ScriptName = Split-Path $PSCommandPath -Leaf
    $PSScriptRoot
    $PSCommandPath
    $ScriptName

<!--more-->
本文国际来源：[Current Script Path](http://community.idera.com/powershell/powertips/b/tips/posts/current-script-path)
