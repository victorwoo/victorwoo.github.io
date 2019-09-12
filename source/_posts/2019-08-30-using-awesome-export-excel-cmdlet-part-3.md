---
layout: post
date: 2019-08-30 00:00:00
title: "PowerShell 技能连载 - 使用超棒的 Export-Excel Cmdlet（第 3 部分）"
description: PowerTip of the Day - Using Awesome Export-Excel Cmdlet (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
这是我们关于 Doug Finke 的强大而免费的 "ImportExcel" PowerShell 模块的迷你系列文章的第 3 部分。在学习这个技能之前，请确保安装了该模块：

```powershell
PS> Install-Module -Name ImportExcel -Scope CurrentUser -Force
```

在第 2 部分中，我们检查了由于数字自动转换导致的错误解释。当原始数据”看起来像“ Excel 公式时会导致另一个问题，它们会被转换为公式并且会在等等打开时出现问题。

以下是重现该问题的示例：一些记录包含以 "=)" 开头的文本，会导致 Excel 认为它是一个公式：

```powershell
# any object-oriented data will do
# we create some sample records via CSV
# to mimick specific issues
$rawData = @'
Data,Name
Test, Tobias
=), Mary
=:-(), Tom
'@ | ConvertFrom-Csv

# create this Excel file
$Path = "$env:temp\report.xlsx"
# make sure the file is deleted so we have no
# effects from previous data still present in the
# file. This requires that the file is not still
# open and locked in Excel
$exists = Test-Path -Path $Path
if ($exists) { Remove-Item -Path $Path}

$rawData |
  Export-Excel -Path $path -ClearSheet -WorksheetName Processes -Show
```

当您运行这段代码时，Excel 将打开但是立即报告非法格式。原始数据将会丢失。

这个问题无法通过一个开关参数解决。相反，您需要手动重新格式化单元格，这给了您很大的灵活性。以下是总体的策略：

* 使用 `Export-Excel` 创建 .xlsx 文件，但不是指定 -Show（在 Excel 中打开文件），而是使用 `-PassThru`。这样就得到了 Excel 对象模型。
* 使用对象模型对单元格进行任意更改
* 使用 `Close-ExcelPackage` 将更改保存到文件中。您现在可以指定 `-Show`，并在 Excel 中打开结果。

```powershell
# any object-oriented data will do
# we create some sample records via CSV
# to mimick specific issues
$rawData = @'
Data,Name
Test, Tobias
=), Mary
=:-(), Tom
'@ | ConvertFrom-Csv

# create this Excel file
$Path = "$env:temp\report.xlsx"
# make sure the file is deleted so we have no
# effects from previous data still present in the
# file. This requires that the file is not still
# open and locked in Excel
$exists = Test-Path -Path $Path
if ($exists) { Remove-Item -Path $Path}

$sheetName = 'Testdata'
$excel = $rawData |
  Export-Excel -Path $path -ClearSheet -WorksheetName $sheetName -PassThru



#region Post-process the column with the misinterpreted formulas
# remove the region to repro the original Excel error
$sheet1 = $excel.Workbook.Worksheets[$sheetName]

# take all cells from row "A"...
$sheet1.Cells['A:A'] |
# ...that are currently interpreted as a formula...
Where-Object Formula |
ForEach-Object {
  # ...construct the original content which is the formula
  # plus a prepended "="
  $newtext = ('={0}' -f $_.Formula)
  # reformat cell to number type "TEXT"
  Set-Format -Address $_ -NumberFormat 'Text' -Value 'dummy'
  # assign the original content to the cell (this cannot be done using Set-Format)
  $_.Value = $newtext
}
#endregion

Close-ExcelPackage -ExcelPackage $excel -Show
```

当您运行这段代码时，Excel 工作簿打开时不会报错，并且第一列能够正确地显示内容。这是由于我们显式地将第一列格式化为“文本”。然后，一旦格式被设置为“文本”，那么公式内容就会作为单元格值插入。

您不会受到“公式”错误信息，也不必通过在其周围添加引号来“屏蔽”内容。

这个示例演示了如何后期处理 Excel 工作簿并且在将结果保存到文件并在 Excel 中打开结果之前增加、更改、重新格式化独立的单元格。

<!--本文国际来源：[Using Awesome Export-Excel Cmdlet (Part 3)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-awesome-export-excel-cmdlet-part-3)-->

