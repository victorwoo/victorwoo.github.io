---
layout: post
date: 2018-03-01 00:00:00
title: "PowerShell 技能连载 - 将值保存到 Excel 工作表中"
description: PowerTip of the Day - Saving Values to Excel Sheet
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
有些时候，您可能会需要更新一个 Excel 工作表中的值。PowerShell 可以操作 Excel 对象模型，不过它很慢。以下是一个打开 Excel 文件，然后写入信息到 A1 单元格，最后保存更改的例子，

请确保您调整了路径，指向一个实际存在的 Excel 文件。

```powershell
$excel = New-Object -ComObject Excel.Application
# open Excel file
$workbook = $excel.Workbooks.Open("c:\test\excelfile.xlsx")

# uncomment next line to make Excel visible
#$excel.Visible = $true

$sheet = $workbook.ActiveSheet
$column = 1
$row = 1
# change content of Excel cell
$sheet.cells.Item($column,$row) = Get-Random
# save changes
$workbook.Save()
$excel.Quit()
```

<!--more-->
本文国际来源：[Saving Values to Excel Sheet](http://community.idera.com/powershell/powertips/b/tips/posts/saving-values-to-excel-sheet)
