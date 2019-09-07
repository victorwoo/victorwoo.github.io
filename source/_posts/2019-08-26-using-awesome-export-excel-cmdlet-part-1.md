---
layout: post
date: 2019-08-26 00:00:00
title: "PowerShell 技能连载 - 使用很棒的 Export-Excel Cmdlet（第 1 部分）"
description: PowerTip of the Day - Using Awesome Export-Excel Cmdlet (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Doug Finke 创建了一个非常棒的 PowerShell 模块 `ImportExcel`，它提供了从 Microsoft Excel 导入和导出数据所需的所有命令。它不需要安装Office。

我们不能涵盖这个模块提供的所有内容，但在本文中，我们将为您提供启动和运行它的基础知识，在后续的技巧中，我们将讨论一些格式化技巧。

要使用 Excel 命令，只需要下载并安装免费的模块：

```powershell
PS> Install-Module -Name ImportExcel -Scope CurrentUser -Force
```

首次运行时，您可能必须同意下载一个 "NuGet" 开源DLL。命令完成后，您现在可以访问大量新的 Excel 命令，其中最重要的是 `Export-Excel`。

您现在可以通过管道将数据直接传给一个 Excel 文件，并且假设在 Microsoft Office 已经安装的情况下，您甚至可以在 Excel 中打开并显示文件（创建 .xlsx 文件不需要 Office）。

以下是一个简单的示例：

```powershell
$Path = "$env:temp\report.xlsx"
Get-Process | Where-Object MainWindowTitle |
    Export-Excel -Path $path -ClearSheet -WorksheetName Processes -Show
```

就是这么简单。创建 Excel 文件从来没有这么容易过。不过，你要记住以下几点：

* 在将数据通过管道传给 `Export-Excel` 之前，使用 `Select-Object` 选择要导出的属性。
* 使用 `-ClearSheet` 清除以前的数据。如果省略此参数，新数据将附加到 .xlsx 文件中的现有数据之后。
* 在创建具有相同名称的新文件之前，您可能需要考虑手动删除旧的 .xlsx 文件。否则，`Export-Excel` 可能会参考旧文件中的现有设置。

<!--本文国际来源：[Using Awesome Export-Excel Cmdlet (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-awesome-export-excel-cmdlet-part-1)-->

