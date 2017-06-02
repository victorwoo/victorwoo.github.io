---
layout: post
title: "PowerShell 技能连载 - 复制命令行历史的工具函数"
date: 2014-07-09 00:00:00
description: PowerTip of the Day - Copying Command History as a Tool
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
在前一个技能中我们演示了如何将之前键入的交互式 PowerShell 命令复制到您喜欢的脚本编辑器中。以下是一个能让操作更加简化的函数。如果您喜欢它，您可以将它加入您的配置脚本，那么就可以随时调用它：

    function Get-MyGeniusInput
    {
      param
      (
        $Count,
        $Minute = 10000
      )
    
      $cutoff = (Get-Date).AddMinutes(-$Minute)
    
      $null = $PSBoundParameters.Remove('Minute')
      $result = Get-History @PSBoundParameters |
        Where-Object { $_.StartExecutionTime -gt $cutoff } |
        Select-Object -ExpandProperty CommandLine 
    
      $count = $result.Count
      $result | clip.exe
      Write-Warning "Copied $count command lines to the clipboard!"
    } 

`Get-MyGeniusInput` 默认将所有命令行历史都复制到剪贴板。通过 `-Count` 参数，您可以指定复制的条数，例如最后 5 条命令。而通过 `-Minute` 参数，您可以指定复制多少分钟之内的历史记录。

    PS> Get-MyGeniusInput -Minute 25
    WARNING: Copied 32 command lines to the clipboard!
    
    PS> Get-MyGeniusInput -Minute 25 -Count 5
    WARNING: Copied 5 command lines to the clipboard!
    
    PS>

<!--more-->
本文国际来源：[Copying Command History as a Tool](http://community.idera.com/powershell/powertips/b/tips/posts/copying-command-history-as-a-tool)
