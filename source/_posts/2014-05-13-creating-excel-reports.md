---
layout: post
title: "PowerShell 技能连载 - 创建 Excel 报表"
date: 2014-05-13 00:00:00
description: PowerTip of the Day - Creating Excel Reports
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 对象可以很容易地通过 Microsoft Excel 打开。只需要将对象导出成 CSV，然后通过关联的应用程序打开 CSV 文件（如果装了 Excel，那么将用 Excel 打开）。

以下代码创建一个当前运行的进程报告，并用 Excel 打开：

    $Path = "$env:temp\$(Get-Random).csv"
    $originalProperties = 'Name', 'Id', 'Company', 'Description', 'WindowTitle'

    Get-Process |
      Select-Object -Property $originalProperties |
      Export-Csv -Path $Path -Encoding UTF8 -NoTypeInformation -UseCulture

    Invoke-Item -Path $Path

请注意 `-UseCulture` 如何根据您的区域设置自动选择正确的分隔符。

<!--本文国际来源：[Creating Excel Reports](http://community.idera.com/powershell/powertips/b/tips/posts/creating-excel-reports)-->
