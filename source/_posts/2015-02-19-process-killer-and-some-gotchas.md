layout: post
date: 2015-02-19 12:00:00
title: "PowerShell 技能连载 - 进程终结器（和一些陷阱）"
description: PowerTip of the Day - Process Killer (and some gotchas)
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
_适用于 PowerShell 3.0 及以上版本_

在前一个技能中我们介绍了如何利用 `Out-GridView` 做一个选择对话框，并且提供了一些建议。一个点子是列出所有桌面应用，并且允许用户选择一个进程并终结它。

要列出所有桌面应用，请试试这段代码：

    PS> Get-Process | Where-Object MainWindowTitle | Select-Object -Property Name, Description, MainWindowTitle, StartTime

这行代码对进程列表进行过滤并只列出设置了 `MainWindowTitle` 的进程。实际上，它返回了一个包含窗体的列表，忽略了所有不可见的后台进程。

接下来，将结果通过管道输出到 `Out-GridView` 并允许单选：

    PS> Get-Process | Where-Object MainWindowTitle | Select-Object -Property Name, Description, MainWindowTitle, StartTime | Out-GridView -Title 'Kill Application' -OutputMode Single | Stop-Process -WhatIf

这行代码将打开一个网格视图窗口，显示所有运行中的进程。当您选中一个进程并点击“确定”按钮，将会杀掉该进程。不过，还差一点：这段示例代码包含了 `-WhatIf` 开关，所以只是 `Stop-Process` 只是模拟操作。

所以这是个好东西，因为您可能会注意到选择一个进程将会导致杀掉所有同名的进程。

这是由于 `Stop-Process` 可以接受两个不同的信息：名字（字符串），或是进程 ID (int)。由于这行代码使用了 `Select-Object` 来筛选属性，并且不包含进程 ID，所以 Stop-Process 将会使用进程名字，并杀掉所有同名的进程。

要实现杀除更具体的进程，请确保包含了进程的 ID：

    PS> Get-Process | Where-Object MainWindowTitle | Select-Object -Property Name, Id, Description, MainWindowTitle, StartTime | Out-GridView -Title 'Kill Application' -OutputMode Single | Stop-Process -WhatIf

<!--more-->
本文国际来源：[Process Killer (and some gotchas)](http://community.idera.com/powershell/powertips/b/tips/posts/process-killer-and-some-gotchas)
