---
layout: post
date: 2018-07-17 00:00:00
title: "PowerShell 技能连载 - 自动生成文档和报告（第 4 部分）"
description: PowerTip of the Day - Automatic Document & Report Generation (Part 4)
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
Iain Brighton 创建了一个名为 "PScribo" 的免费的 PowerShell 模块，可以快速地创建文本、HTML 或 Word 格式的文档和报告。

要使用这个模块，只需要运行这条命令：

```powershell
Install-Module -Name PScribo -Scope CurrentUser -Force
```

再之前的技能中，我们介绍了如何生成动态的表格。今天，我们来学习如何根据特定的条件，例如配置错误，高亮某个单元格。

要实现这个目的，我们使用 `Set-Style` 将格式应用到独立的属性上。以下示例代码选择所有 `StartType` 的值为 `Automatic` 但 `Status` 的值是 `Stopped` 的对象，并将 `HighlightedService` 应用在 `Status` 属性上：

```powershell
# https://github.com/iainbrighton/PScribo
# help about_document

# create a folder to store generated documents
$OutPath = "c:\temp\out"
$exists = Test-Path -Path $OutPath
if (!$exists) { $null = New-Item -Path $OutPath -ItemType Directory -Force }

# generate document
Document 'HighlightedReport'  {

    # get the service data to use:
    # generate the service information to use
    # (requires PowerShell 5 because prior to PowerShell 5, Get-Service does not supply
    # StartType - alternative: use Get-WmiObject -Class Win32_Service, and adjust
    # property names)

    # IMPORTANT: run this information through Select-Object to get a cloned copy
    # of the original objects so that style information can be appended
    $services = Get-Service | 
            Select-Object -Property DisplayName, Status, StartType | 
            Sort-Object -Property DisplayName

    # write heading
    Paragraph "Services ($($services.Count) Services found):"
    
    # define style to use for highlighting
    Style -Name HighlightedService -Color Red -BackgroundColor Yellow -Bold

    # apply a different format to cell "Status" for all objects where
    # status is "Stopped" and StartType is "Automatic"
    $services | 
        Where { $_.Status -eq 'Stopped' -and $_.StartType -eq 'Automatic'} | 
        Set-Style -Property Status -Style HighlightedService
    
    # create the table    
    $services | 
        Table -Columns DisplayName,Status,StartType -Headers 'Display Name','Status','Startup Type' -Tabs 1
    
    
} | 
Export-Document -Path $OutPath -Format Word,Html,Text

# open the generated documents
explorer $OutPath
```

<!--more-->
本文国际来源：[Automatic Document & Report Generation (Part 4)](http://community.idera.com/powershell/powertips/b/tips/posts/automatic-document-report-generation-part-4)
