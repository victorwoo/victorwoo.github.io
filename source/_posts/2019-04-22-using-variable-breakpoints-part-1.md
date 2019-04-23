---
layout: post
date: 2019-04-22 00:00:00
title: "PowerShell 技能连载 - 使用变量断点（第 1 部分）"
description: PowerTip of the Day - Using Variable Breakpoints (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在调试过程中，变量断点可能非常有用。当一个变量改变时，变量断点能够自动生效并进入调试器。如果您知道当异常发生时某个变量变为某个设置的值（或是 NULL 值），那么可以让调试器只在那个时候介入。

以下例子演示如何使用变量断点。最好在脚本的顶部定义它们，因为您可以用 `$PSCommandPath` 来检验断点所需要的实际脚本文件路径：

```powershell
# initialize variable breakpoints (once)
# break when $a is greater than 10
Set-PSBreakpoint -Variable a -Action { if ($a -gt 10) { break }} -Mode Write -Script $PSCommandPath

# run the code to debug
do
{
    $a = Get-Random -Minimum -20 -Maximum 20
    "Drawing: $a"
} while ($true)
```

请确保执行之前先保存脚本：调试始终需要一个物理文件。

如您所见，当变量 `$a` 被赋予一个大于 10 的值时，调试器会自动中断下来。您可以使用 "`exit`" 命令继续，用 "`?`" 查看所有调试器选项，并且按 `SHIFT`+`F4` 停止。

要移除所有断点，运行这行代码：

```powershell
PS C:\> Get-PSBreakpoint | Remove-PSBreakpoint
```

<!--本文国际来源：[Using Variable Breakpoints (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-variable-breakpoints-part-1)-->

