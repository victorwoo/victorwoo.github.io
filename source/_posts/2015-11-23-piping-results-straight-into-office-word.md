---
layout: post
date: 2015-11-23 12:00:00
title: "PowerShell 技能连载 - 将结果通过管道直接传给 Office Word"
description: PowerTip of the Day - Piping Results Straight Into Office Word
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
只需要几行代码，您就可以实现一个 `Out-OfficeWord` 指令。它接受传入的数据并将它们插入一个新的 Word 文档中（假设 Word 已经安装）。

    #requires -Version 1
    
    function Out-OfficeWord
    {
      param
      (
        $Font = 'Courier',
        
        $FontSize = 12,
        
        $Width = 80,
        
        [switch]
        $Landscape
      )
    
      $Text = $Input | Out-String -Width $Width
      
      $WordObj = New-Object -ComObject Word.Application
      $document = $WordObj.Documents.Add()
      $document.PageSetup.Orientation = [Int][bool]$Landscape
      $document.Content.Text = $Text
      $document.Content.Font.Size = $FontSize
      $document.Content.Font.Name = $Font
      $document.Paragraphs | ForEach-Object { $_.SpaceAfter = 0 }
      $WordObj.Visible = $true
    }

要在 Word 中建立一个正在运行中的进程列表，只需要运行这段代码：

    Get-Process | Out-OfficeWord -Landscape -Font Consolas -FontSize 8

接下来，您可以将结果另存为 PDF、改进格式，或打印出来。

<!--本文国际来源：[Piping Results Straight Into Office Word](http://community.idera.com/powershell/powertips/b/tips/posts/piping-results-straight-into-office-word)-->
