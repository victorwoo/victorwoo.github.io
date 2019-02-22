---
layout: post
date: 2018-07-18 00:00:00
title: "PowerShell 技能连载 - 自动生成文档和报告（第 4 部分）"
description: PowerTip of the Day - Automatic Document & Report Generation (Part 5)
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

要使用这个模块，只需要运行这段代码：

```powershell
# https://github.com/iainbrighton/PScribo 
# help about_document 

# create a folder to store generated documents 
$OutPath = "c:\temp\out"
$exists = Test-Path -Path $OutPath
if (!$exists) { $null = New-Item -Path $OutPath -ItemType Directory -Force }


Document 'Report' {
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

在前一个技能中，我们演示了如何通过将对象转换为纯文本的方式，将结果从 cmdlet 添加到文本报告：

```powershell
# https://github.com/iainbrighton/PScribo 
# help about_document 

# create a folder to store generated documents 
$OutPath = "c:\temp\out"
$exists = Test-Path -Path $OutPath
if (!$exists) { $null = New-Item -Path $OutPath -ItemType Directory -Force }


Document 'Report' {
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

这是很直接的方法，但是比较土。如果您希望向复杂的表格添加对象结果，请试试这种方法：

```powershell
# https://github.com/iainbrighton/PScribo 
# help about_document 

# create a folder to store generated documents 
$OutPath = "c:\temp\out"
$exists = Test-Path -Path $OutPath
if (!$exists) { $null = New-Item -Path $OutPath -ItemType Directory -Force }

# generate document 
Document 'BIOS' {
# get an object with rich information
$info = Get-WmiObject -Class Win32_BIOS

# find out the property names that have actual information
$properties = $info | Get-Member -MemberType *property |
Select-Object -ExpandProperty Name |
Where-Object { 

$info.$_ -ne $null -and $info.$_ -ne ''

} |
Sort-Object

# turn each property into a separate object
$infos = $properties | ForEach-Object { 
[PSCustomObject]@{
Name = $_
Value = $info.$_
}


}

Paragraph -Style Heading1 "BIOS Information"

# generate a table with one line per property
$infos |
# select the properties to display, and the header texts to use
Table -Columns Name,Value -Headers 'Item','Content' -Width 0

} |
Export-Document -Path $OutPath -Format Word

# open the generated documents 
explorer $OutPath
```

它的基本思想史为每个对象属性创建新的对象，然后以表格的方式显示它们。这段代码显示 BIOS 信息的详细报告。

<!--本文国际来源：[Automatic Document & Report Generation (Part 5)](http://community.idera.com/powershell/powertips/b/tips/posts/automatic-document-report-generation-part-5)-->
