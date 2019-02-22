---
layout: post
date: 2015-11-20 12:00:00
title: "PowerShell 技能连载 - 从 WMI 中搜索有用的信息"
description: PowerTip of the Day - Search WMI for Useful Information
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
WMI 是一个很好的信息源，但要找到正确的 WMI 类来查询并不总是那么容易。

一下是一个小小的搜索工具：它提示输入一个关键字，然后根据在 WMI 中搜索所有合适的关键字。结果将显示在一个网格视图窗口中，然后您可以选择一个类并按下“确定”按钮，该工具将查询出匹配的结果：

    #requires -Version 3
    
    function Search-WMI
    {
        param([Parameter(Mandatory=$true)]$Keyword)
        
        Get-WmiObject -Class "Win32_*$Keyword*" -List |
        Where-Object { $_.Properties.Count -gt 6 } |
        Where-Object { $_.Name -notlike 'Win32_Perf*' } |
        Sort-Object -Property Name |
        Select-Object -Property @{Name='Select one of these classes'; Expression={$_.Name }} |
        Out-GridView -Title 'Choose one' -OutputMode Single |
        ForEach-Object {
            Get-WmiObject -Class $_.'Select one of these classes' | Out-GridView
        }
    }
    
    Search-WMI -Keyword network

<!--本文国际来源：[Search WMI for Useful Information](http://community.idera.com/powershell/powertips/b/tips/posts/search-wmi-for-useful-information)-->
