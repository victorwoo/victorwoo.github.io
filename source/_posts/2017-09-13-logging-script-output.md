---
layout: post
date: 2017-09-13 00:00:00
title: "PowerShell 技能连载 - 记录脚本输出"
description: PowerTip of the Day - Logging Script Output
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
有一系列办法能记录脚本的输出结果，但是一个非常偷懒的办法是使用 `Start-Transcript`。在 PowerShell 5 中，这个 cmdlet 不仅在 powershell.exe 中支持，而且在所有宿主中都支持。所以您在 PowerShell ISE 或其它编辑器中都可以使用它。另外，transcript 支持嵌套，所以如果您写一个脚本，您可以安全地在起始处加上 `Start-Transcript` 并且在结尾处加上 `Stop-Transcript`。

`Start-Transcript` 将所有输出输出写入一个文本文件。如果您没有指定路径，那么该 cmdlet 将会使用默认路径。您只需要确保脚本确实产生了可记录的输出。

要使脚本更详细，请结合这个技巧一起使用：当您将赋值语句放入一对括号 ()，该赋值语句也会输出赋值的数据。这个输出结果也会被 transcript 接收到。请试试一下代码：

```powershell
# default assignment, no output
$a = Get-Service
$a.Count

# assignment in parentheses, outputs the assignment
($b = Get-Service)
$b.Count
```

<!--more-->
本文国际来源：[Logging Script Output](http://community.idera.com/powershell/powertips/b/tips/posts/logging-script-output)
