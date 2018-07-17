---
layout: post
date: 2018-07-16 00:00:00
title: "PowerShell 技能连载 - 自动生成文档和报告（第 3 部分）"
description: PowerTip of the Day - Automatic Document & Report Generation (Part 3)
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

在前一个技能中，我们介绍了如何生成动态的表格。今天，我们将介绍调整表格和显示任意数据是多么容易。我们从前一个示例中取出服务列表：

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

只需要做少许调整，示例代码将返回所有 ad 用户（假设您安装了 `ActiveDirectory` 模块并且能操作 AD）：

```powershell
# https://github.com/iainbrighton/PScribo
# help about_document

# create a folder to store generated documents
$OutPath = "c:\temp\out"
$exists = Test-Path -Path $OutPath
if (!$exists) { $null = New-Item -Path $OutPath -ItemType Directory -Force }

# generate document
Document 'ADUser'  {
    # get 40 AD user to illustrate
    $user = Get-ADUser -Filter * -ResultSetSize 40 -Properties mail | 
        Select-Object -Property Name, mail, SID

    Paragraph -Style Heading1 "AD User Liste"
    
    # generate a table with one line per user
    $user | 
        # select the properties to display, and the header texts to use
        Table -Columns Name, mail, SID -Headers 'Employee','Email','SID' -Width 0
    
} | 
Export-Document -Path $OutPath -Format Word

# open the generated documents
explorer $OutPath
```

<!--more-->
本文国际来源：[Automatic Document & Report Generation (Part 3)](http://community.idera.com/powershell/powertips/b/tips/posts/automatic-document-report-generation-part-3)
