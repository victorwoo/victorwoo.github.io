---
layout: post
date: 2017-08-18 00:00:00
title: "PowerShell 技能连载 - 创建 Excel 报表（第三部分——独立操作工作簿）"
description: "PowerTip of the Day - Creating Excel Reports (Part 3 – Individually Accessing Workbook)"
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
有些时候您可能需要创建非表格形式的，个性化的报表。

对于这种情况， PowerShell 可以连接到 Excel 的对象模型。通过这种方法，您可以操作独立的单元格，读写它们的内容，甚至对它们进行格式化。这给你最大的灵活度。然而，它的缺点是需要大量的编码，因为您需要人工操作每一个单元格。并且，通过 .NET 操作 COM 对象相对比较慢。

以下是起步的代码。它展示了如何连接到 Excel，存取独立的单元格，并应用格式设置：

```powershell
#requires -Version 2.0
Add-Type -AssemblyName System.Drawing

# accessing excel via COM
$excel = New-Object -ComObject Excel.Application
# make it visible (for debugging only, can be set to $false later in production)
$excel.Visible = $true

# add workbook
$workbook = $excel.Workbooks.Add()

# access workbook cells
$workbook.ActiveSheet.Cells.Item(1,1) = 'Hey!'

# formatting cell
$workbook.ActiveSheet.Cells.Item(1,1).Font.Size = 20

$r = 200
$g = 100
$b = 255
[System.Drawing.ColorTranslator]::ToOle([System.Drawing.Color]::FromArgb(255,$r,$g,$b))
$workbook.ActiveSheet.Cells.Item(1,1).Font.Color = $r + ($g * 256) + ($b * 256 * 256)

# saving workbook to file
$Path = "$env:temp\excel.xlsx"
$workbook.SaveAs($Path)
```

<!--more-->
本文国际来源：[Creating Excel Reports (Part 3 – Individually Accessing Workbook)](http://community.idera.com/powershell/powertips/b/tips/posts/creating-excel-reports-part-3-individually-accessing-workbook)
