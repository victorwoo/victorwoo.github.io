layout: post
date: 2015-08-31 11:00:00
title: "PowerShell 技能连载 - 映射网络驱动器（第 3 部分）"
description: PowerTip of the Day - Mapping Network Drives (Part 3)
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
如果您从 VBScript 迁移到 PowerShell，您也许会记得 VBScript 如何映射网络驱动器。这个选项在 PowerShell 中仍然有效。

    $helper = New-Object -ComObject WScript.Network
    
    $helper.MapNetworkDrive('O:','\\dc-01\somefolder',$true)
    $helper.EnumNetworkDrives()
    
    Test-Path -Path O:\
    explorer.exe O:\
    Get-PSDrive -Name O
    
    
    $helper.RemoveNetworkDrive('O:', $true, $true)

如果您希望以不同的凭据登录，请使用这种方式：

    $helper.MapNetworkDrive('O:','\\dc-01\somefolder',$true, 'training\user02', 'topSecret')

<!--more-->
本文国际来源：[Mapping Network Drives (Part 3)](http://community.idera.com/powershell/powertips/b/tips/posts/mapping-network-drives-part-3)
