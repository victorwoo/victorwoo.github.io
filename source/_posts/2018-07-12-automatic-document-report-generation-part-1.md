---
layout: post
date: 2018-07-12 00:00:00
title: "PowerShell 技能连载 - 自动生成文档和报告（第 1 部分）"
description: PowerTip of the Day - Automatic Document & Report Generation (Part 1)
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

下一步，您可以类似这样生成简单的文档：

```powershell
# https://github.com/iainbrighton/PScribo
# help about_document

# create a folder to store generated documents
$OutPath = "c:\temp\out"
$exists = Test-Path -Path $OutPath
if (!$exists) { $null = New-Item -Path $OutPath -ItemType Directory -Force }


Document 'Report'  {
    Paragraph -Style Heading1 "System Inventory for $env:computername"
    Paragraph -Style Heading2 'BIOS Information'
    Paragraph 'BIOS details:' -Bold
    $bios = Get-WmiObject -Class Win32_BIOS | Out-String
    Paragraph $bios.Trim()
} |
Export-Document -Path $OutPath -Format Word,Html,Text

# open the generated documents
explorer $OutPath
```

<!--本文国际来源：[Automatic Document & Report Generation (Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/automatic-document-report-generation-part-1)-->
