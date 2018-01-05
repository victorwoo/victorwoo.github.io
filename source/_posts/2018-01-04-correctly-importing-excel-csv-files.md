---
layout: post
date: 2018-01-04 00:00:00
title: "PowerShell 技能连载 - 正确地导入 Excel 的 CSV 文件"
description: PowerTip of the Day - Correctly Importing Excel CSV Files
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
如果您导出一个 Excel 工作表到 CSV 文件中，并且希望将这个文件导入 PowerShell，以下是实现方法：

```powershell
$path = 'D:\sampledata.csv'

Import-Csv -Path $path -UseCulture -Encoding Default
```

重要的参数有 `-UseCulture`（自动使用和 Excel 在您系统中所使用一致的分隔符）和 `-Encoding Default`（只有使用此设置，所有特殊字符才能保持原样）。

<!--more-->
本文国际来源：[Correctly Importing Excel CSV Files](http://community.idera.com/powershell/powertips/b/tips/posts/correctly-importing-excel-csv-files)
