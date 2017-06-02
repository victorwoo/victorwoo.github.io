---
layout: post
title: "显示、隐藏 PowerShell"
date: 2014-06-23 00:00:00
description: Show-PowerShell Hide-PowerShell
categories: powershell
tags:
- powershell
- window
- module
---
在 WPF 之周中，有个朋友希望有个最小化 PowerShell 窗口的例子。

以下是一个快速实现该需求的 module。只要将以下代码复制粘贴到 Documents\WindowsPowerShell\Packages\PowerShell\PowerShell.psm1 即可。

    $script:showWindowAsync = Add-Type –memberDefinition @"
    [DllImport("user32.dll")]
    public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
    "@ -name "Win32ShowWindowAsync" -namespace Win32Functions –passThru
    
    function Show-PowerShell() {
    $null = $showWindowAsync::ShowWindowAsync((Get-Process –id $pid).MainWindowHandle, 10)
    }
    
    function Hide-PowerShell() {
    $null = $showWindowAsync::ShowWindowAsync((Get-Process –id $pid).MainWindowHandle, 2)
    }

现在，您可以用这段代码来显示或隐藏 PowerShell：

    Add-Module PowerShell
    # Minimize PowerShell
    Hide-PowerShell
    sleep 2
    # Then Restore it
    Show-PowerShell

希望这篇文章有所帮助。
James Brundage[MSFT]

译者注：`ShowWindowAsync()` 的第二个参数取值范围可以参照 API 文档 [ShowWindow function](http://technet.microsoft.com/zh-cn/magazine/ms633548.aspx)
[本文国际来源](http://blogs.msdn.com/b/powershell/archive/2008/06/03/show-powershell-hide-powershell.aspx)
