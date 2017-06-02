---
layout: post
date: 2014-09-04 11:00:00
title: "PowerShell 技能连载 - 合并执行结果"
description: PowerTip of the Day - Combining Results
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

假设您想检查可疑的服务状态，例如启动类型为“自动”而状态处于停止的，或检查服务的 ExitCode 为非正常值的。

以下是一些示例代码，演示如何查询这些场景并将执行结果合并为一个变量。

`Sort-Object` 确保您的结果在输出到 grid view 窗口之前是不重复的。

    $list = @()
    
    $list += Get-WmiObject -Class Win32_Service -Filter 'State="Stopped" and StartMode="Auto" and ExitCode!=0' | 
      Select-Object -Property Name, DisplayName, ExitCode, Description, PathName, DesktopInteract 
    
    $list += Get-WmiObject -Class Win32_Service -Filter 'ExitCode!=0 and ExitCode!=1077' | 
      Select-Object -Property Name, DisplayName, ExitCode, Description, PathName, DesktopInteract 
    
    
    $list |
      # remove identical (-Unique)
      Sort-Object -Unique -Property Name | 
      Out-GridView

<!--more-->
本文国际来源：[Combining Results](http://community.idera.com/powershell/powertips/b/tips/posts/combining-results)
