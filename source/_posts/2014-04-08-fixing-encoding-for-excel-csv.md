layout: post
title: "PowerShell 技能连载 - 修正 Excel CSV 的编码"
date: 2014-04-08 00:00:00
description: PowerTip of the Day - Fixing Encoding for Excel CSV
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
当您将 Microsoft Excel 的数据保存为 CSV 格式时，很不幸的是保存的编码和 `Import-Csv` 的缺省编码并不匹配。所以当您将 CSV 文件导入 PowerShell 时，无论您指定哪种编码，特殊字符都会变成乱码。

以下是一个我从 Excel 导出的 list.csv 文件，它包含一些特殊字符。如果您使用缺省编码，特殊字符会变成乱码，并且如果您指定了 -Encoding 参数，无论您传什么值，特殊字符都不会显示回原来正常的状态：

![](/img/2014-04-08-fixing-encoding-for-excel-csv-001.png)

当您模拟在这些场景中 `Import-Csv` 的行为时，它很意外地可以完美处理：

![](/img/2014-04-08-fixing-encoding-for-excel-csv-002.png)

这说明要正确地读取 Excel CSV 文件，您必须显式地指定“缺省”编码（这引出了一个问题：当您未指定编码的时候，缺省使用的是什么编码）：

![](/img/2014-04-08-fixing-encoding-for-excel-csv-003.png)

<!--more-->
本文国际来源：[Fixing Encoding for Excel CSV](http://community.idera.com/powershell/powertips/b/tips/posts/fixing-encoding-for-excel-csv)
