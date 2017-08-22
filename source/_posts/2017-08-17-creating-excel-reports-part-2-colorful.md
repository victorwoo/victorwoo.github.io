---
layout: post
date: 2017-08-17 00:00:00
title: "PowerShell 技能连载 - 创建 Excel 报表（第二部分——彩色）"
description: "PowerTip of the Day - Creating Excel Reports (Part 2 – Colorful)"
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
当从 CSV 中导入数据到 Excel 时，您无法指定格式，包括字体和颜色等。从 HTML 数据中导入 Excel 则可以包含格式。以下是一个演示创建一个带格式的彩色 Excel 报告是多么容易的例子，假设报表中包含一张表格：

```powershell
#requires -Version 2.0
$html = & {
    '<table>'
    '<tr><th>Name</th><th>Status</th></tr>'
    Get-Service |
    ForEach-Object {
        if ($_.Status -eq 'Running')
        {
            $color = 'green'
        }
        else
        {
            $color = 'red'
        }
        
        '<tr><td>{0}</td><td bgcolor="{2}">{1}</td></tr>' -f $_.Name, $_.Status, $color
    
    }
    '</table>'
}

$PathHTML = "$env:temp\report.htm"
$html | Set-Content $PathHTML -Encoding UTF8
# open as HTML
Invoke-Item -Path $PathHTML
# open as Excel report 
Start-Process -FilePath excel -ArgumentList """$PathHTML"""
```

<!--more-->
本文国际来源：[Creating Excel Reports (Part 2 – Colorful)](http://community.idera.com/powershell/powertips/b/tips/posts/creating-excel-reports-part-2-colorful)
