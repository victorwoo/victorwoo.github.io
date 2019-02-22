---
layout: post
date: 2015-10-15 11:00:00
title: "PowerShell 技能连载 - 创建临时文件名"
description: PowerTip of the Day - Creating Temporary File Names
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您只是需要创建一个临时文件名（而不是真的需要创建该文件），而且您希望控制文件的扩展名，以下是一个实现该需求的简单函数：

    $elements = @()
    $elements += [System.IO.Path]::GetTempPath()
    $elements += [System.Guid]::NewGuid()
    $elements += 'csv'
    
    
    $randomPath = '{0}{1}.{2}' -f $elements
    $randomPath

您可以很容易地根据它创建您自己的函数：

    function New-TemporaryFileName($Extension='txt')
    {
      $elements = @()
      $elements += [System.IO.Path]::GetTempPath()
      $elements += [System.Guid]::NewGuid()
      $elements += $Extension.TrimStart('.')
    
    
      '{0}{1}.{2}' -f $elements
    }

这是该函数的使用方法：

    PS C:\> New-TemporaryFileName
    C:\Users\Tobias\AppData\Local\Temp\8d8e5001-2be8-469d-9bc8-e2e3324cce66.txt
    
    PS C:\> New-TemporaryFileName ps1
    C:\Users\Tobias\AppData\Local\Temp\412c40df-e691-44c1-8c94-f7ce30bb4875.ps1
    
    PS C:\> New-TemporaryFileName csv
    C:\Users\Tobias\AppData\Local\Temp\47b1a65f-2705-4926-8a72-21f05430f2c5.csv

<!--本文国际来源：[Creating Temporary File Names](http://community.idera.com/powershell/powertips/b/tips/posts/creating-temporary-filenames)-->
