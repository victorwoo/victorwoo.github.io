layout: post
date: 2015-09-18 11:00:00
title: "PowerShell 技能连载 - 将哈希表用作条件化的代码库"
description: PowerTip of the Day - Using Hash Table as Conditional Code Repository
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
脚本中平时经常需要检测一个文件夹是否存在，如果不存在则创建：

    #requires -Version 1
    
    $path = 'c:\testfolder'
    $exists = Test-Path -Path $path
    
    if ($exists)
    {
      $null = New-Item -Path $path -ItemType Directory
      Write-Warning -Message 'Folder created'
    }
    else
    {
      Write-Warning -Message 'Folder already present'
    }

以下是一种很不常见的方法，以一种不同的概念实现相同的功能：

    #requires -Version 1
    
    $Creator = @{
      $true = { Write-Warning 'Folder already present'}
      $false = {$null = New-Item -Path $Path -ItemType Directory
                Write-Warning 'Folder created'}
    }
    
    
    $Path = 'c:\testfolder2'
    & $Creator[(Test-Path $Path)]

实际上，这段脚本用了一个哈希表（`$Creator)`）来存储两个脚本块，而它的键是 `$true` 和 `$false`。

现在，根据文件夹存在与否，哈希表将返回合适的脚本块，接下来被 `&`（调用）操作符执行。

哈希表用这种方式来模拟从句。


<!--more-->
本文国际来源：[Using Hash Table as Conditional Code Repository](http://community.idera.com/powershell/powertips/b/tips/posts/using-hash-table-as-conditional-code-repository)
