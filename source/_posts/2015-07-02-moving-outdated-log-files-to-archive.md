---
layout: post
date: 2015-07-02 11:00:00
title: "PowerShell 技能连载 - 将过期的日志存档"
description: PowerTip of the Day - Moving Outdated Log Files to Archive
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有时，你会需要在文件超过一定的日期之后将它们移动到一个存档文件夹。

这个例子演示了如何检测过期文件的基本策略，以及如何将它们移动到存档文件夹：

    #requires -Version 1
    # how old (in days) would obsolete files be
    $Days = 14
    
    # where to look for obsolete files
    $Path = $env:windir
    $Filter = '*.log'
    
    # where to move obsolete files
    $DestinationPath = 'c:\archive'
    
    # make sure destination folder exists
    $destinationExists = Test-Path -Path $DestinationPath
    if (!$destinationExists)
    {
        $null = New-Item -Path $DestinationPath -ItemType Directory
    }
    
    $cutoffDate = (Get-Date).AddDays(-$Days)
    
    Get-ChildItem -Path $Path -Filter $Filter -Recurse -ErrorAction SilentlyContinue |
    Where-Object -FilterScript {
        $_.LastWriteTime -lt $cutoffDate
    } |
    Move-Item -Destination c:\archive -WhatIf

这个示例脚本在 Windows 文件夹和它的子文件夹中查找所有扩展名为 _*.log_ 的日志文件。所有超过 14 天（在过去 14 天内没有修改过）的日志文件将被移动到 _c:\archive_ 目录中。如果该文件夹不存在，则会自动创建。

请注意这只是一个示例脚本。您可能需要管理员权限才能确实将文件移出 Windows 文件夹。

<!--本文国际来源：[Moving Outdated Log Files to Archive](http://community.idera.com/powershell/powertips/b/tips/posts/moving-outdated-log-files-to-archive)-->
