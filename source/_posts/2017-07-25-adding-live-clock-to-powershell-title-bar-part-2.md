---
layout: post
date: 2017-07-25 00:00:00
title: "PowerShell 技能连载 - 在 PowerShell 标题栏中添加实时时钟（第二部分）"
description: PowerTip of the Day - Adding Live Clock to PowerShell Title Bar (Part 2)
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
在前一个技能中我们演示了一段代码，可以在后台线程中更新 PowerShell 标题栏，显示一个实时时钟。

难道不能更完美一点，显示当前的路径位置？挑战之处在于，如何让后台线程知道前台 PowerShell 的当前路径？

有一个名为 `$ExecutionContext` 的 PowerShell 变量可以提供关于上下文状态的各种有用信息，包括当前路径。我们将 `$ExecutionContext` 从前台传递给后台线程，该后台线程就可以显示当前前台的路径。

试试看：

```powershell
$code =
{
    # submit the host process RawUI interface and the execution context
    param($RawUi, $ExecContext)

    do
    {
        # find the current location in the host process
        $location = $ExecContext.SessionState.Path.CurrentLocation
        # compose the time and date display
        $time = Get-Date -Format 'HH:mm:ss dddd MMMM d'
        # compose the title bar text
        $title = "$location     $time"
        # output the information to the title bar of the host process
        $RawUI.WindowTitle = $title
        # wait a half second
        Start-Sleep -Milliseconds 500
    } while ($true)
}
$ps = [PowerShell]::Create()
$null = $ps.AddScript($code).AddArgument($host.UI.RawUI).AddArgument($ExecutionContext)
$handle = $ps.BeginInvoke()
```

当您运行这段代码时，PowerShell 的状态栏显示当前路径和实时时钟。当您切换当前路径时，例如运行 "`cd c:\windows`"，标题栏会立刻更新。

用以上代码可以处理许多使用场景：

- 您可以在午餐时间快到时显示通知
- 您可以在指定时间之后结束 PowerShell 会话
- 您可以在标题栏中显示 RSS 订阅项目

<!--more-->
本文国际来源：[Adding Live Clock to PowerShell Title Bar (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/adding-live-clock-to-powershell-title-bar-part-2)
