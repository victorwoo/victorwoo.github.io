---
layout: post
date: 2016-02-23 12:00:00
title: "PowerShell 技能连载 - 直接使用 .NET 类型"
description: PowerTip of the Day - Using .NET Types Directly
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
Cmdlet 内含了纯 .NET 代码，所以感谢 cmdlet，我们通常无需接触 .NET 代码。不过，如果您需要的话仍然可以使用。以下是一系列调用示例，演示了如何调用 .NET 方法：

    #requires -Version 2
    [System.Convert]::ToString(687687687, 2)
    
    [Math]::Round(4.6)
    
    [Guid]::NewGuid()
    
    [System.IO.Path]::ChangeExtension('c:\test.txt', 'bak')
    
    [System.Net.DNS]::GetHostByName('dell1')
    [System.Net.DNS]::GetHostByAddress('192.168.1.124')
    
    [Environment]::SetEnvironmentVariable()
    
    # dangerous, save your work first
    [Environment]::FailFast('Oops')
    
    Add-Type -AssemblyName PresentationFramework
    $dialog = New-Object Microsoft.Win32.OpenFileDialog
    $dialog.ShowDialog()
    $dialog.FileName

<!--more-->
本文国际来源：[Using .NET Types Directly](http://community.idera.com/powershell/powertips/b/tips/posts/using-net-types-directly)
