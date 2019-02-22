---
layout: post
date: 2018-07-13 00:00:00
title: "PowerShell 技能连载 - 自动生成文档和报告（第 2 部分）"
description: PowerTip of the Day - Automatic Document & Report Generation (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Iain Brighton 创建了一个名为 "PScribo" 的免费的 PowerShell 模块，可以快速地创建文本、HTML 或 Word 格式的文档和报告。

要使用这个模块，只需要运行这条命令：

```powershell
Install-Module -Name PScribo -Scope CurrentUser -Force
```

今天，我们将生成一个包含动态表格内容的文档：

```powershell
# https://github.com/iainbrighton/PScribo
# help about_document

# create a folder to store generated documents
$OutPath = "c:\temp\out"
$exists = Test-Path -Path $OutPath
if (!$exists) { $null = New-Item -Path $OutPath -ItemType Directory -Force }

# generate document
Document 'ServiceReport'  {
    # generate the service information to use
    # (requires PowerShell 5 because prior to PowerShell 5, Get-Service does not supply
    # StartType - alternative: use Get-WmiObject -Class Win32_Service, and adjust
    # property names)
    $services = Get-Service | Select-Object -Property DisplayName, Status, StartType

    Paragraph -Style Heading1 "System Inventory for $env:computername"
    Paragraph -Style Heading2 "Services ($($services.Count) Services found):"
    
    # generate a table with one line per service
    $services | 
        # select the properties to display, and the header texts to use
        Table -Columns DisplayName, Status, StartType -Headers 'Service Name','Current State','Startup Type' -Width 0
    
} | 
Export-Document -Path $OutPath -Format Word,Html,Text

# open the generated documents
explorer $OutPath 
```

当您运行这段代码时，它生成三个名为 ServiceReport.docx/html/txt 的文件。如您所见，该报告包含表格形式的服务列表。

<!--本文国际来源：[Automatic Document & Report Generation (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/automatic-document-report-generation-part-2)-->
