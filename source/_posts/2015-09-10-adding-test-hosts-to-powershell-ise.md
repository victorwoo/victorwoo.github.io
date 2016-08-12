layout: post
date: 2015-09-10 11:00:00
title: "PowerShell 技能连载 - 向 PowerShell ISE 添加测试宿主"
description: PowerTip of the Day - Adding Test Hosts to PowerShell ISE
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
要在随 PowerShell 3.0 以上版本发行的 PowerShell ISE 中打开一个新的测试宿主，这是一个小小的辅助函数：

    #requires -Version 3
    
    function New-PSHost
    {
        param
        (
            [Parameter(Mandatory = $true)]
            $Name
        )
    
        $newTab = $psise.PowerShellTabs.Add()
        $newTab.DisplayName = $Name
    }

当您运行该函数并且输入 `New-PSHost` 之后，您会收到一个输入名字的提示。请键入新的测试宿主的名字，并按下 `ENTER` 键，PowerShell ISE 将会在一个新的 PowerShell 标签页中打开一个新的 PowerShell 宿主，并且标签页以您起的名字命名。

<!--more-->
本文国际来源：[Adding Test Hosts to PowerShell ISE](http://powershell.com/cs/blogs/tips/archive/2015/09/10/adding-test-hosts-to-powershell-ise.aspx)
