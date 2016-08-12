layout: post
date: 2016-02-05 12:00:00
title: "PowerShell 技能连载 - 将窗口置于前台"
description: PowerTip of the Day - Bringing Window in the Foreground
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
PowerShell 可以使用 `Add-Type` 来操作 Windows 内置的 API 功能。通过这种方法，可以很容易地将所有进程的窗口置于前台。以下是您需要的函数：

    #requires -Version 2
    function Show-Process($Process, [Switch]$Maximize)
    {
      $sig = '
        [DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
        [DllImport("user32.dll")] public static extern int SetForegroundWindow(IntPtr hwnd);
      '
    
      if ($Maximize) { $Mode = 3 } else { $Mode = 4 }
      $type = Add-Type -MemberDefinition $sig -Name WindowAPI -PassThru
      $hwnd = $process.MainWindowHandle
      $null = $type::ShowWindowAsync($hwnd, $Mode)
      $null = $type::SetForegroundWindow($hwnd)
    }

要测试 `Show-Process`，以下是一段示例代码，演示如何使用它：

    # launch Notepad minimized, then make it visible
    $notepad = Start-Process notepad -WindowStyle Minimized -PassThru
    Start-Sleep -Seconds 2
    Show-Process -Process $notepad
    # switch back to PowerShell, maximized
    Start-Sleep -Seconds 2
    Show-Process -Process (Get-Process -Id $PID) -Maximize
    # switch back to Notepad, maximized
    Start-Sleep -Seconds 2
    Show-Process -Process $notepad -Maximize
    # switch back to PowerShell, normal window
    Start-Sleep -Seconds 2
    Show-Process -Process (Get-Process -Id $PID)

<!--more-->
本文国际来源：[Bringing Window in the Foreground](http://powershell.com/cs/blogs/tips/archive/2016/02/05/bringing-window-in-the-foreground.aspx)
