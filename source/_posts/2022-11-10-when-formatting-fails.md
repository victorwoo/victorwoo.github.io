---
layout: post
date: 2022-11-10 00:00:00
title: "PowerShell 技能连载 - 当格式化失败时"
description: PowerTip of the Day - When Formatting Fails
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
您在使用 PowerShell 时可能会遇到一个奇怪的格式问题：当您一行一行执行代码时，得到的输出结果和以整体的方式执行一段代码有所不同。

这是要执行的示例代码：

    Get-Process -Id $pid
    Get-Date
    Get-Service -Name Spooler

当您将三行代码作为脚本整体运行时，只有第一个命令返回表格，后两个显示列表。但是，当您逐行执行代码时，它们的格式不同，并显示为表格，甚至是单行纯文本。

这是 PowerShell 实时输出格式的副作用：当输出格式化器遇到第一个返回数据时，它必须决定格式化和写入，即表头。所有剩余的数据将插入到该输出格式中。

每当您的脚本返回多个对象并且这些对象具有不同类型时，PowerShell 就会意识到这些对象不适合现有表设计。在这种情况下，所有后续对象将格式化成列表视图。

如果您想更好地控制此行为，则可以随时将输出发送到 `Out-Default`，这将关闭当前的输出。任何后续对象都将启动新的输出格式。以下代码将始终显示相同的显示格式，无论您是作为脚本运行还是单独运行命令：

```powershell
Get-Process -Id $pid | Out-Default
Get-Date | Out-Default
Get-Service -Name Spooler
```

<!--本文国际来源：[When Formatting Fails](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/when-formatting-fails)-->

