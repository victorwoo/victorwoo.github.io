---
layout: post
date: 2017-07-24 00:00:00
title: "PowerShell 技能连载 - 在 PowerShell 标题栏中添加实时时钟（第一部分）"
description: PowerTip of the Day - Adding Live Clock to PowerShell Title Bar (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
要持续地更新 PowerShell 的标题栏，例如显示当前的日期和时间，您需要一个后台线程来处理这个工作。如果没有后台线程，PowerShell 会一直不停地忙于更新标题栏，导致无法使用。

以下是一个演示了如何在标题栏显示实时时钟的代码片段：

```powershell
$code =
{
    # submit the host process RawUI interface and the execution context
    param($RawUi)

    do
    {
        # compose the time and date display
        $time = Get-Date -Format 'HH:mm:ss dddd MMMM d'
        # compose the title bar text
        $title = "Current Time: $time"
        # output the information to the title bar of the host process
        $RawUI.WindowTitle = $title
        # wait a half second
        Start-Sleep -Milliseconds 500
    } while ($true)
}
$ps = [PowerShell]::Create()
$null = $ps.AddScript($code).AddArgument($host.UI.RawUI)
$handle = $ps.BeginInvoke()
```

这里最关键的是将 `$host.UI.RawUI` 对象从 PowerShell 前台传递给后台线程代码。只有这样，后台线程才能存取 PowerShell 前台拥有的标题栏对象。

<!--本文国际来源：[Adding Live Clock to PowerShell Title Bar (Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/adding-live-clock-to-powershell-title-bar-part-1)-->
