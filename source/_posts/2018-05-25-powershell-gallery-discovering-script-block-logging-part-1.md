---
layout: post
date: 2018-05-25 00:00:00
title: "PowerShell 技能连载 - PowerShell 陈列架：探索脚本块日志（第 1 部分）"
description: 'PowerTip of the Day - PowerShell Gallery: Discovering Script Block Logging (Part 1)'
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
在前一个技能中我们解释了如何获取 PowerShellGet 并在您的 PowerShell 版本中运行。现在我们来看看 PowerShell 陈列架能够如何方便地扩展 PowerShell 功能。

脚本块日志是 PowerShell 5 以及之后版本的新功能。当 PowerShell 引擎编译（执行）一个命令，它将命令的执行记录到一个内部的日志文件。默认情况下，只记录了少数被认为与安全性相关的命令。通过一个名为 `ScriptBlockLoggingAnalyzer` 的免费模块，您可以找到 PowerShell 在您机器上记录日志的代码：

```powershell
# install the extension module from the Gallery (only required once!)
Install-Module ScriptBlockLoggingAnalyzer -Scope CurrentUser -Force

# show all logged events
Get-SBLEvent | Out-GridView
```

请注意 `ScriptBlockLoggingAnalyzer` 当前只适用于 Windows PowerShell。PowerShell Core 使用相同的机制，但是不同的日志。由于 PowerShell Core 中的日志名称还在开发中，所以您需要手工调整模块来适应 PowerShell Core。

<!--more-->
本文国际来源：[PowerShell Gallery: Discovering Script Block Logging (Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/powershell-gallery-discovering-script-block-logging-part-1)
