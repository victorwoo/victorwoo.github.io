layout: post
date: 2015-06-24 11:00:00
title: "PowerShell 技能连载 - 列出所有脚本中的所有变量"
description: PowerTip of the Day - Listing All Variables in All Scripts
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
是否希望列出 PowerShell ISE 中打开的所有文件中的变量清单？

以下是一段能够创建这样清单的代码：

    $psise.CurrentPowerShellTab.Files |
      ForEach-Object {
            $errors = $null
            [System.Management.Automation.PSParser]::Tokenize($_.Editor.Text, [ref]$errors) |
            Where-Object { $_.Type -eq 'Variable'} |
            Select-Object -Property Content |
            Add-Member -MemberType NoteProperty -Name Script -Value $_.DisplayName -PassThru 
        } |
        Sort-Object -Property Content, Script -Unique

<!--more-->
本文国际来源：[Listing All Variables in All Scripts](http://community.idera.com/powershell/powertips/b/tips/posts/listing-all-variables-in-all-scripts)
