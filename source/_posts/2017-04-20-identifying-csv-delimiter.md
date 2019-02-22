---
layout: post
date: 2017-04-20 00:00:00
title: "PowerShell 技能连载 - 检测 CSV 的分隔符"
description: PowerTip of the Day - Identifying CSV Delimiter
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当使用 `Import-Csv` 导入一个 CSV 文件，需要指定一个分隔符。如果用错了，显然会导入失败。您需要事先知道 CSV 文件使用的分隔符。

以下是一个简单的实践，展示了如何判断一个给定的 CSV 文件的分隔符：

```powershell
function Get-CsvDelimiter($Path)
{
    # get the header line
    $headerLine = Get-Content $Path | Select-Object -First 1

    # examine header line per character
    $headerline.ToCharArray() |
        # find all non-alphanumeric characters
        Where-Object { $_ -notlike '[a-z0-9äöüß"()]' } |
        # find the one that occurs most often
        Group-Object -NoElement |
        Sort-Object -Descending -Property Count |
        # return it
        Select-Object -First 1 -ExpandProperty Name
}
```

以下是一个测试：

```powershell
PS> Get-Date | Export-Csv -Path $env:temp\test.csv -NoTypeInformation

PS> Get-CsvDelimiter -Path $env:temp\test.csv
,

PS> Get-Date | Export-Csv -Path $env:temp\test.csv -NoTypeInformation -UseCulture

PS> Get-CsvDelimiter -Path $env:temp\test.csv
;

PS> Get-Date | Export-Csv -Path $env:temp\test.csv -NoTypeInformation -Delimiter '#'

PS> Get-CsvDelimiter -Path $env:temp\test.csv
#
```

<!--本文国际来源：[Identifying CSV Delimiter](http://community.idera.com/powershell/powertips/b/tips/posts/identifying-csv-delimiter)-->
