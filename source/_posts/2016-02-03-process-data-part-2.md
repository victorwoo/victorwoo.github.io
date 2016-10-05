layout: post
date: 2016-02-03 12:00:00
title: "PowerShell 技能连载 - 处理数据（第 2 部分）"
description: PowerTip of the Day - Process Data (Part 2)
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
在第 1 部分中我们演示了一个 PowerShell 函数如何同时从参数和管道获取输入，并且实时处理它。这是最有效的方法并节省内存开销。

然而，有时需要先收集所有数据，待所有数据收集完成以后，一次性处理所有数据。以下是一个收集所有收到的数据并等所有数据都到齐以后才开始处理的例子：

    #requires -Version 2
    function Collect-Data
    {
      param
      (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [Object]
        [AllowEmptyString()] 
        $Object
      )
    
      begin
      {
        $bucket = New-Object System.Collections.ArrayList
      }
    
      process
      {
        $null = $bucket.Add($Object)
      }
      end
      {
        $count = $bucket.Count
        Write-Host "Received $count objects." -ForegroundColor Yellow
        $bucket | Out-String
      }
    }

请注意 `Collect-Data` 如何既从参数又从管道获取信息：

    PS C:\>  Collect-Data -Object 1,2,3
    Received 3 objects.
    1
    2
    3
    
    
    PS C:\> 1..3 |  Collect-Data
    Received 3 objects.
    1
    2
    3

有两件事值得一提：千万不要用一个纯数组来收集信息。而是使用一个 `ArraryList` 对象，因为它添加新的元素比较快。并且避免将 `$input` 用于类似用途的自动变量。`$input` 只能用于管道输入并且忽略提交到参数的值。

<!--more-->
本文国际来源：[Process Data (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/process-data-part-2)
