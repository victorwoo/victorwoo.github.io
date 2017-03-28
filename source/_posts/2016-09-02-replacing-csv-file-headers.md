layout: post
date: 2016-09-02 00:00:00
title: "PowerShell 技能连载 - 替换 CSV 文件列名"
description: PowerTip of the Day - Replacing CSV File Headers
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
*支持 PowerShell 2 以上版本*

当读取 CSV 数据的时候，可能会希望重命名 CSV 的列名，以下是一个简单的实现：只需要一行一行地读取文本，并跳过第一行（第一行包括 CSV 的列名）。然后，将表头替换成一个自定义的列名：

```powershell
$header = ‘NewHeader1’, 'NewHeader2', 'NewHeader3'

Get-Content N:\somepathtofile\userlist.csv -Encoding Default | 
 Select-Object -Skip 1 |
 ConvertFrom-CSV -UseCulture -Header $header
```

<!--more-->
本文国际来源：[Replacing CSV File Headers](http://community.idera.com/powershell/powertips/b/tips/posts/replacing-csv-file-headers)
