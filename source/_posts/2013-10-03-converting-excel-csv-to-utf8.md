layout: post
title: "PowerShell 技能连载 - 将Excel导出的CSV转换为UTF-8编码"
date: 2013-10-03 00:00:00
description: PowerTip of the Day - Converting Excel CSV to UTF8
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
当您导出 Microsoft Excel 数据表到 CSV 文件时，Excel缺省将保存为 ANSI 编码的 CSV 文件。这是很糟糕的，因为当您用 `Import-Csv` 导入数据到 PowerShell 中时，特殊字符将会截断（译者注：例如中文出现乱码）。

要确保特殊字符不会丢失，您必须确保导入数据之前 CSV 文件采用的是 UTF-8 编码：

	$Path = 'c:\temp\somedata.csv'
	(Get-Content -Path $Path) | Set-Content -Path $Path -Encoding UTF8 

<!--more-->

本文国际来源：[Converting Excel CSV to UTF8](http://community.idera.com/powershell/powertips/b/tips/posts/converting-excel-csv-to-utf8)
