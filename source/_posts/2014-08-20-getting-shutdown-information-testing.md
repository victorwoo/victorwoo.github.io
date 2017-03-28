layout: post
date: 2014-08-20 11:00:00
title: "PowerShell 技能连载 - 获取关机信息"
description: PowerTip of the Day - Getting Shutdown Information
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
_适用于 PowerShell 所有版本_

Windows 在系统事件日志中记录了所有的关机事件。您可以从那儿提取和分析信息。

以下是一个读取适当的事件日志记录、从 ReplacementStrings 数组中读取相关的信息，并以对象数组的方式返回关机信息的函数。

    function Get-ShutdownInfo
    {
      
      Get-EventLog -LogName system -InstanceId 2147484722 -Source user32 |
      ForEach-Object {
        
        $result = 'dummy' | Select-Object -Property ComputerName, TimeWritten, User, Reason, Action, Executable
        
        $result.TimeWritten = $_.TimeWritten
        $result.User = $_.ReplacementStrings[6]
        $result.Reason = $_.ReplacementStrings[2]
        $result.Action = $_.ReplacementStrings[4]
        $result.Executable = Split-Path -Path $_.ReplacementStrings[0] -Leaf
        $result.ComputerName = $_.MachineName
        
        $result 
      }
    } 
    

现在要检查关机问题就容易多了：

    PS> Get-ShutdownInfo |  Out-GridView

<!--more-->
本文国际来源：[Getting Shutdown Information](http://community.idera.com/powershell/powertips/b/tips/posts/getting-shutdown-information-testing)
