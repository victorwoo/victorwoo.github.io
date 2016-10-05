layout: post
title: "PowerShell 技能连载 - 从命令行获取参数"
date: 2014-04-30 00:00:00
description: PowerTip of the Day - Getting Arguments from Command Line
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
在前一个技巧中，我们演示了如何从命令行中提取命令名，并忽略所有参数。今天，您将学习到如何用一个函数同时获取到命令名和参数。该函数将命令行分割为实际的命令名和它的参数，并返回一个自定义对象：

    function Get-Argument
    {
      param
      (
        $CommandLine
      )
      
      $result = 1 | Select-Object -Property Command, Argument
    
      if ($CommandLine.StartsWith('"')) 
      { 
        $index = $CommandLine.IndexOf('"', 1)
        if ($index -gt 0)
        {
          $result.Command = $CommandLine.SubString(0, $index).Trim('"')
          $result.Argument = $CommandLine.SubString($index+1).Trim()
          $result
        }
      }
      else
      {
        $index = $CommandLine.IndexOf(' ')
        if ($index -gt 0)
        {
          $result.Command = $CommandLine.SubString(0, $index)
          $result.Argument = $CommandLine.SubString($index+1).Trim()
          $result
        }
      }
    }
    
    
    
    Get-Argument -CommandLine 'notepad c:\test'
    Get-Argument -CommandLine '"notepad.exe" c:\test'

结果如下：

![](/img/2014-04-30-getting-arguments-from-command-line-001.png)

这是一个实际应用中的例子：它获取所有运行中的进程，并返回每个进程的命令名和参数：

    Get-WmiObject -Class Win32_Process |
      Where-Object { $_.CommandLine } |
      ForEach-Object {
        Get-Argument -CommandLine $_.CommandLine
      }  

以下是结果的样子：

![](/img/2014-04-30-getting-arguments-from-command-line-002.png)

既然命令和参数都分开了，您还可以像这样为信息分组：

    Get-WmiObject -Class Win32_Process |
      Where-Object { $_.CommandLine } |
      ForEach-Object {
        Get-Argument -CommandLine $_.CommandLine
      } |
      Group-Object -Property Command |
      Sort-Object -Property Count -Descending |
      Out-GridView 

<!--more-->
本文国际来源：[Getting Arguments from Command Line](http://community.idera.com/powershell/powertips/b/tips/posts/getting-arguments-from-command-line)
