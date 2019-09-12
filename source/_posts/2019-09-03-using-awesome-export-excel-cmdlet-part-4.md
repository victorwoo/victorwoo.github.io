---
layout: post
date: 2019-09-03 00:00:00
title: "PowerShell 技能连载 - 使用超棒的 Export-Excel Cmdlet（第 4 部分）"
description: PowerTip of the Day - Using Awesome Export-Excel Cmdlet (Part 4)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
这是我们关于 Doug Finke 的强大而免费的 "ImportExcel" PowerShell 模块的迷你系列文章的第 4 部分。在学习这个技能之前，请确保安装了该模块：

```powershell
PS> Install-Module -Name ImportExcel -Scope CurrentUser -Force
```

在第 3 部分中，我们研究了由于公式自动转换而导致的错误解析数据，并研究了后期处理单个单元格格式的方式。让我们检查一下数组引起的问题。

以下是一些重现该现象的代码。在我们的示例中，这是最后 10 条系统事件的事件日志数据，它恰好包含了一个数组（替换字符串），并且显示完全不正常：

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
  Export-Excel -Path $path -ClearSheet -WorksheetName $sheetName -Show
```

当 Excel 打开时，您可以看见 "ReplacementStrings" 列只显示数据类型 (`System.String[]`) 而不是实际的数据。这是 Excel 遇到数组的通常行为，所以 `Export-Excel` 对此无能为力。

相反地，在将将数组通过管道输出到 `Export-Excel` 命令之前转换为字符串是您的责任——用 `-join` 操作符可以很容易实现：

```powershell
# get some raw data that contains arrays
$rawData = Get-EventLog -LogName System -Newest 10 |
            Select-Object -Property TimeWritten, ReplacementStrings, InstanceId


# create this Excel file
$Path = "$env:temp\report.xlsx"
# make sure the file is deleted so we have no
# effects from previous data still present in the
# file. This requires that the file is not still
# open and locked in Excel:
$exists = Test-Path -Path $Path
if ($exists) { Remove-Item -Path $Path}

$sheetName = 'Testdata'
$rawData |
  ForEach-Object {
    # convert column "ReplacementStrings" from array to string
    $_.ReplacementStrings = $_.ReplacementStrings -join ','
    # return the changed object
    $_
  } |
  Export-Excel -Path $path -ClearSheet -WorksheetName $sheetName -Show
```

当您做了这步操作之后，包含数组的属性在 Excel 中也可以正确显示。`-join` 对任何对象都有效。只需要确保指定了分割数组元素的分隔符。

<!--本文国际来源：[Using Awesome Export-Excel Cmdlet (Part 4)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-awesome-export-excel-cmdlet-part-4)-->

