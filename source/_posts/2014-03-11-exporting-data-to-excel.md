---
layout: post
title: "PowerShell 技能连载 - 导出数据到 Excel"
date: 2014-03-11 00:00:00
description: PowerTip of the Day - Exporting Data to Excel
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
您可以轻松地在 PowerShell 中将对象数据转化为 CSV 文件。以下代码生成当前进程的 CSV 报告：

![](/img/2014-03-11-exporting-data-to-excel-001.png)

要在 Microsoft Excel 中打开 CSV 文件，您可以使用 `Invoke-Item` 来打开文件，但是这仅当您的 CSV 文件扩展名确实关联到 Excel 应用程序的时候才有效。

以下代码将确保在 Microsoft Excel 中打开 CSV 文件。它展示了一种超出您 Excel 应用（假设它已经安装了，并且无须检测它是否存在）的方法：

    $report = "$env:temp\report.csv"
    $ExcelPath = 'C:\Program Files*\Microsoft Office\OFFICE*\EXCEL.EXE'
    $RealExcelPath = Resolve-Path -Path $ExcelPath | Select-Object -First 1 -ExpandProperty Path
    & $RealExcelPath $report

<!--本文国际来源：[Exporting Data to Excel](http://community.idera.com/powershell/powertips/b/tips/posts/exporting-data-to-excel)-->
