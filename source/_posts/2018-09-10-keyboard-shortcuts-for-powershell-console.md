---
layout: post
date: 2018-09-10 00:00:00
title: "PowerShell 技能连载 - PowerShell 控制台的键盘快捷方式"
description: PowerTip of the Day - Keyboard Shortcuts for PowerShell Console
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
PowerShell 控制台从 5.0 版开始发布了一个名为 `PSReadLine` 的模块，它不仅可以对命令做语法着色，还有更多的功能。它包含持久化的命令历史，并且可以将自定义命令绑定到键盘快捷方式上。

请看这个示例：

```powershell
Set-PSReadlineKeyHandler -Chord Ctrl+H -ScriptBlock { 
  Get-History | 
  Out-GridView -Title 'Select Command' -PassThru | 
  Invoke-History 
}
```

当您在 PowerShell 控制台中运行这段代码（它不能在 PowerShell ISE 中运行！），按下 `CTRL` + `H` 打开一个网格视图窗口，这个窗口中列出了所有命令行历史。您可以轻松地选择一个命令并执行它。

显然，这不仅是一个示例。您可以将任何脚本块绑定到未使用的键盘快捷方式，例如提交变更到 Git，或是打开喜爱的滚动新闻条。

<!--more-->
本文国际来源：[Keyboard Shortcuts for PowerShell Console](http://community.idera.com/powershell/powertips/b/tips/posts/keyboard-shortcuts-for-powershell-console)
