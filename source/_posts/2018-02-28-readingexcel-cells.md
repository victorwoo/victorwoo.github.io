---
layout: post
date: 2018-02-28 00:00:00
title: "PowerShell 技能连载 - 读取 Excel 单元格"
description: PowerTip of the Day - Reading Excel Cells
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有些时候，您可能会需要从 Excel 工作表中读取信息。PowerShell 可以操作 Microsoft Excel 对象模型，虽然它的速度很慢。

以下是一段延时如何操作 Excel 单元格的示例代码。请确保您调整了以下代码中的路径，指向一个实际存在的 Excel 文件。该代码将读取 A1 单元格的内容：

```powershell
$excel = New-Object -ComObject Excel.Application
# open Excel file
$workbook = $excel.Workbooks.Open("c:\test\excelfile.xlsx")
    
# uncomment next line to make Excel visible
#$excel.Visible = $true
    
$sheet = $workbook.ActiveSheet
$column = 1
$row = 1
$info = $sheet.cells.Item($column, $row).Text
$excel.Quit()
    
    
"Cell A1 contained '$info'"
```

<!--本文国际来源：[Reading Excel Cells](http://community.idera.com/powershell/powertips/b/tips/posts/readingexcel-cells)-->
