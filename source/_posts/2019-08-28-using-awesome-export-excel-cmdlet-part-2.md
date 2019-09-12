---
layout: post
date: 2019-08-28 00:00:00
title: "PowerShell 技能连载 - 使用超棒的 Export-Excel Cmdlet（第 2 部分）"
description: PowerTip of the Day - Using Awesome Export-Excel Cmdlet (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
这是我们关于 Doug Finke 的强大而免费的 "ImportExcel" PowerShell 模块的迷你系列文章的第 2 部分。在学习这个技能之前，请确保安装了该模块：

```powershell
    PS> Install-Module -Name ImportExcel -Scope CurrentUser -Force
```

当您导出数据到 Excel 文件中时，您有时可能会遇到 Excel 错误解释的数据。例如，电话号码常常被错误地解释为数字型数据。以下是一个重现该问题的示例：

```powershell
# any object-oriented data will do
# we create some sample records via CSV
# to mimick specific issues
$rawData = @'
Phone,Name
+4915125262524, Tobias
0766256725672, Mary
00496253168722567, Tom
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

如您所见，当 Excel 打开时，电话号码自动转换为整形。

要避免这个自动转换，请使用 `-NoNumberConversion` 参数，并且指定不需要转换的列：

```powershell
# any object-oriented data will do
# we create some sample records via CSV
# to mimick specific issues
$rawData = @'
Phone,Name
+4915125262524, Tobias
0766256725672, Mary
00496253168722567, Tom
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
  Export-Excel -Path $path -ClearSheet -WorksheetName Processes -Show -NoNumberConversion Phone
```

现在，"Phone" 列不再处理为数字，电话号码显示正常了。

<!--本文国际来源：[Using Awesome Export-Excel Cmdlet (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-awesome-export-excel-cmdlet-part-2)-->

