---
layout: post
date: 2015-08-20 11:00:00
title: "PowerShell 技能连载 - 快速查找脚本"
description: PowerTip of the Day - Quickly Finding Scripts
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
要在“我的文档”文件夹的任意位置中快速定位一个 PowerShell 脚本，请试试这个 `Find-Script` 函数：

    #requires -Version 3
    function Find-Script
    {
      param
      (
        [Parameter(Mandatory = $true)]
        $SearchPhrase,
        $Path = [Environment]::GetFolderPath('MyDocuments')
      )

      Get-ChildItem -Path $Path  -Filter *.ps1 -Recurse -ErrorAction SilentlyContinue |
      Select-String -Pattern $SearchPhrase -List |
      Select-Object -Property Path, Line |
      Out-GridView -Title "All Scripts containing $SearchPhrase" -PassThru |
      ForEach-Object -Process {
        ise $_.Path
      }
    }

像这样运行：

    Find-Script 'childitem'

这将返回一个在您的文档文件夹中包含搜索关键词的所有 PowerShell 脚本。当您在网格视图窗口中选择了某些脚本并点击确认按钮后，这些脚本将会自动由 PowerShell ISE 打开。

要设置一个不同的搜索跟路径，请使用 `-Path` 参数。通过这种方式，您可以很容易地在您的 USB 媒体或是网络路径中搜索。

<!--本文国际来源：[Quickly Finding Scripts](http://community.idera.com/powershell/powertips/b/tips/posts/quickly-finding-scripts)-->
