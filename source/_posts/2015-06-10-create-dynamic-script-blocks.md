layout: post
date: 2015-06-10 11:00:00
title: "PowerShell 技能连载 - 创建动态脚本块"
description: PowerTip of the Day - Create Dynamic Script Blocks
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
脚本块是一段可执行的 PowerShell 代码。您通常可以将语句包裹在大括号中创建脚本块。

若要在脚本中动态创建脚本块，以下是将一个字符串转换为脚本块的方法。

    $scriptblock = [ScriptBlock]::Create('notepad')

通过这种方法，您的代码首先以字符串的形式创建代码，然后将字符串转换为脚本块，然后将脚本块传递给您需要的 cmdlet（例如 `Invoke-Command`）：

    PS> Invoke-Command -ScriptBlock 'notepad'
    Cannot convert  the "notepad" value of type "System.String" to type  
    "System.Management.Automation.ScriptBlock". (raised by:  Invoke-Command)
    
    PS> Invoke-Command -ScriptBlock ([ScriptBlock]::Create('notepad'))

<!--more-->
本文国际来源：[Create Dynamic Script Blocks](http://community.idera.com/powershell/powertips/b/tips/posts/create-dynamic-script-blocks)
