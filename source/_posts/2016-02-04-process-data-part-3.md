---
layout: post
date: 2016-02-04 12:00:00
title: "PowerShell 技能连载 - 处理数据（第 3 部分）"
description: PowerTip of the Day - Process Data (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在第 1 和 第 2 部分，您学到了如何 PowerShell 函数如何处理通过参数和通过管道传入的信息。在这部分中，我们打算介绍一个函数如何接收多行文本并将它加工成一个字符串。

这个函数同时接受参数和管道传入的多行文本。该函数使用 `StringBuilder` 对象来收集所有的文本行，然后将收到的所有文本行合并成单个字符串：

    #requires -Version 2
    function Collect-Text
    {
      param
      (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [String[]]
        [AllowEmptyString()]
        $Text
      )

      begin
      {
        $sb = New-Object System.Text.StringBuilder
      }

      process
      {
       foreach ($line in $Text)
       {
         $null = $sb.AppendLine($line)
       }
      }
      end
      {
        $result = $sb.ToString()
        $result
      }
    }

请注意如何既支持通过参数，也支持通过管道传递文本行：

    PS C:\> Collect-Text -Text 'Line 1', '', 'Line 2'
    Line 1

    Line 2


    PS C:\> 'Line 1', '', 'Line 2' | Collect-Text
    Line 1

    Line 2

请注意参数：它使用了 `[AllowEmptyString()]` 属性。它确保可以接受空字符串参数。在 mandatory （必须）参数中，如果没有这个属性，是不允许空字符串的。

<!--本文国际来源：[Process Data (Part 3)](http://community.idera.com/powershell/powertips/b/tips/posts/process-data-part-3)-->
