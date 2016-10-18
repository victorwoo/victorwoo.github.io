layout: post
date: 2016-02-22 12:00:00
title: "PowerShell 技能连载 - 使用工作流来并发执行代码"
description: PowerTip of the Day - Using Workflows to Parallelize Code
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
如果您希望同时执行多个任务，以下有多种方法用 Powershell 实现。一种是使用工作流。它们是 PowerShell 3.0 中引入的：

    #requires -Version 3
    workflow Test-ParallelForeach
    {
      param
      (
        [String[]]
        $ComputerName
      )
    
      foreach -parallel -throttlelimit 8 ($Machine in $ComputerName)
      {
        "Begin $Machine"
        Start-Sleep -Seconds (Get-Random -min 3 -max 5)
        "End $Machine"
      }
    }
    
    $list = 1..20
    
    Test-ParallelForeach -ComputerName $list | Out-GridView

`Test-ParallelForeach` 处理一个计算机列表（在这个例子中，是一个数字列表）。它们同时执行。要控制资源的使用，并行循环将节流限制为 8，所以所以在这个例子中的 20 台计算机是 8 个一组处理的。

请注意使用工作流需要更多地了解它们的架构和限制。这个例子关注于工作流提供的并行循环技术。

<!--more-->
本文国际来源：[Using Workflows to Parallelize Code](http://community.idera.com/powershell/powertips/b/tips/posts/using-workflows-to-parallelize-code)
