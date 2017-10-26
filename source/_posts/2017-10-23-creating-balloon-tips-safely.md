---
layout: post
date: 2017-10-23 00:00:00
title: "PowerShell 技能连载 - Creating Balloon Tips Safely"
description: PowerTip of the Day - Creating Balloon Tips Safely
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
受到 MVP 同行 Boe Prox 一篇文章的启发，编写了一个精致的创建气球状提示对话框的函数。您可以在 Boe 的原始文章中找到背景信息：[https://mcpmag.com/articles/2017/09/07/creating-a-balloon-tip-notification-using-powershell.aspx](https://mcpmag.com/articles/2017/09/07/creating-a-balloon-tip-notification-using-powershell.aspx)。

您可以找到许多关于如何显示气球状提示的使用技巧，但大多数都只是一个不能操作的任务栏图标。

以下函数是基于 Boe 的点子，但可以确保不需要全局变量或任何其它会污染 PowerShell 环境的东西。当您调用 `Show-BalloonTip` 时，一个气球状提示将从桌面的右下角滑入。您可以点击打开这个工具提示并再次关闭它，或者取消它。当您取消它时，它的图标会留在任务栏的托盘区域。当您点击托盘图标，该气球状图标会再次显示。

```powershell
function Show-BalloonTip
{
    param
    (
        [Parameter(Mandatory=$true)][string]$Text,
        [string]$Title = "Message from PowerShell",
        [ValidateSet('Info','Warning','Error','None')][string]$Icon = 'Info'
    )

    Add-Type -AssemblyName  System.Windows.Forms

    # we use private variables only. No need for global scope
    $balloon = New-Object System.Windows.Forms.NotifyIcon 
    $cleanup = 
    {    
        # this gets executed when the user clicks the balloon tip dialog

        # take the balloon from the event arguments, and dispose it
        $event.Sender.Dispose()
        # take the event handler names also from the event arguments,
        # and clean up
        Unregister-Event  -SourceIdentifier $event.SourceIdentifier
        Remove-Job -Name $event.SourceIdentifier
        $name2 = "M" + $event.SourceIdentifier
        Unregister-Event  -SourceIdentifier $name2
        Remove-Job -Name $name2
    }
    $showBalloon = 
    {
        # this gets executed when the user clicks the tray icon
        $event.Sender.ShowBalloonTip(5000) 
    }

    # use unique names for event handlers so you can open multiple balloon tips
    $name = [Guid]::NewGuid().Guid

    # subscribe to the balloon events
    $null = Register-ObjectEvent -InputObject $balloon -EventName BalloonTipClicked -Source $name -Action $cleanup
    $null = Register-ObjectEvent -InputObject $balloon -EventName MouseClick -Source "M$name" -Action $showBalloon

    # use the current application icon as tray icon
    $path = (Get-Process -id $pid).Path
    $balloon.Icon  = [System.Drawing.Icon]::ExtractAssociatedIcon($path) 

    # configure the balloon tip
    $balloon.BalloonTipIcon  = $Icon
    $balloon.BalloonTipText  = $Text
    $balloon.BalloonTipTitle  = $Title

    # make the tray icon visible
    $balloon.Visible  = $true 
    # show the balloon tip
    $balloon.ShowBalloonTip(5000) 
}
```

<!--more-->
本文国际来源：[Creating Balloon Tips Safely](http://community.idera.com/powershell/powertips/b/tips/posts/creating-balloon-tips-safely)
