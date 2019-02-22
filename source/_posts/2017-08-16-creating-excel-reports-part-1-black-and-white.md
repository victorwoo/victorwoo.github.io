---
layout: post
date: 2017-08-16 00:00:00
title: "PowerShell 技能连载 - 创建 Excel 报表（第一部分——黑白）"
description: "PowerTip of the Day - Creating Excel Reports (Part 1 – Black and White)"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
用 PowerShell 创建一个最简单的 Excel 报表只需要几行代码：将结果导出为 CSV 文件，然后将它作为参数启动 Excel：

```powershell
#requires -Version 2.0

$timestamp = Get-Date -Format 'yyyy-MM-dd HH-mm-ss'
$Path = "$env:temp\Excel Report $timestamp.csv"

Get-Service |
  Export-Csv -Path $Path -Encoding UTF8 -UseCulture -NoTypeInformation

Start-Process -FilePath excel -ArgumentList """$Path"""
```

有一些需要注意的事项：

- Excel 打开一个文件时会将它锁定。所以请在文件名之前加上时间戳或其它唯一的识别名。否则，当您多次运行脚本而没有关闭之前的文档会遇到错误。
- 当导出数据到 CSV 时，请使用 UTF-8 编码，来保留特殊字符。
- 同样地，确保 CSV 和 Excel 使用相同的分隔符。只需要使用 `-UseCulture` 来使用注册表中设置的分隔符即可。
- 当启动 Excel 时，请确保将路径置于双引号中，否则，如果路径中包含空格，Excel 将找不到该文件。

<!--本文国际来源：[Creating Excel Reports (Part 1 – Black and White)](http://community.idera.com/powershell/powertips/b/tips/posts/creating-excel-reports-part-1-black-and-white)-->
