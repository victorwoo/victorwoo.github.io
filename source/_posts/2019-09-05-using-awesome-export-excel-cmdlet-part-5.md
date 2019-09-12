---
layout: post
date: 2019-09-05 00:00:00
title: "PowerShell 技能连载 - 使用超棒的 Export-Excel Cmdlet（第 5 部分）"
description: PowerTip of the Day - Using Awesome Export-Excel Cmdlet (Part 5)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
这是我们关于 Doug Finke 的强大而免费的 "ImportExcel" PowerShell 模块的迷你系列文章的第 5 部分。在学习这个技能之前，请确保安装了该模块：

```powershell
PS> Install-Module -Name ImportExcel -Scope CurrentUser -Force
```

在第 4 部分中，我们研究了由于在输入数据中包含数组而导致的误读数据。正如您所看到的，您只需要使用 `-join` 操作符将数组转换为字符串，Excel 就可以正确地显示数组，即逗号分隔值的列表。

但是，如果希望在单独的行中显示数组元素，并使用换行符呢?

默认情况下，Excel 只会在选定单元格的输入框中显示单独的行，而不是在所有单元格中：

```powershell
# get some raw data that contains arrays
$rawData = Get-EventLog -LogName System -Newest 10 |
            Select-Object -Property TimeWritten, ReplacementStrings, InstanceId


# create this Excel file
$Path = "$env:temp\report.xlsx"
# make sure the file is deleted so we have no
# effects from previous data still present in the
# file. This requires that the file is not still
# open and locked in Excel
$exists = Test-Path -Path $Path
if ($exists) { Remove-Item -Path $Path}

$sheetName = 'Testdata'
$rawData |
  ForEach-Object {
    # convert column "ReplacementStrings" from array to string
    $_.ReplacementStrings = $_.ReplacementStrings -join "`r`n"
    # return the changed object
    $_
  } |
  Export-Excel -Path $path -ClearSheet -WorksheetName $sheetName -Show
```

当您运行这段代码时，"ReplacementStrings" 中的数组将会正确地转换为多行文本，但是您不会在工作表中看到它。只有当您单击某个单元格时才会看到输入区域中显示多行文本。

当您把我们前面部分的信息组合起来时，可以很容易地对 Excel 文件进行后期处理，并像这样将单元格格式化为“文本”和“自动换行”：

```powershell
# get some raw data that contains arrays
$rawData = Get-EventLog -LogName System -Newest 10 |
            Select-Object -Property TimeWritten, ReplacementStrings, InstanceId


# create this Excel file
$Path = "$env:temp\report.xlsx"
# make sure the file is deleted so we have no
# effects from previous data still present in the
# file. This requires that the file is not still
# open and locked in Excel
$exists = Test-Path -Path $Path
if ($exists) { Remove-Item -Path $Path}

$sheetName = 'Testdata'

# save the Excel object model by using -PassThru instead of -Show
$excel = $rawData |
  ForEach-Object {
    # convert column "ReplacementStrings" from array to string
    $_.ReplacementStrings = $_.ReplacementStrings -join "`r`n"
    # return the changed object
    $_
  } |
  Export-Excel -Path $path -ClearSheet -WorksheetName $sheetName -AutoSize -PassThru

#region Post-process the column with the misinterpreted formulas
# remove the region to repro the original Excel error
$sheet1 = $excel.Workbook.Worksheets[$sheetName]
# reformat cell to number type "TEXT" with WordWrap and AutoSize
Set-Format -Address $sheet1.Cells['B:B'] -NumberFormat 'Text' -WrapText -AutoSize
#endregion

Close-ExcelPackage -ExcelPackage $excel -Show
```

<!--本文国际来源：[Using Awesome Export-Excel Cmdlet (Part 5)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-awesome-export-excel-cmdlet-part-5)-->

