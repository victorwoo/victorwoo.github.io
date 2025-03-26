---
layout: post
date: 2023-05-01 09:04:34
title: "PowerShell 技能连载 - 列出所有域控制器"
description: PowerTip of the Day - Listing All Domain Controllers
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
要快速获取所有域控制器的列表，请运行以下命令：

```powershell
Get-AdDomainController -Filter * | Select-Object -Property Name, Domain, Forest, IPv4Address, Site | Export-Csv -Path $env:temp\report.csv -UseCulture -NoTypeInformation -Encoding Default
```

当然，您需要登录到域，并且需要访问“ActiveDirectory” PowerShell 模块。

该命令会在您的临时文件夹中创建一个 CSV 文件，可用 Excel 打开。只需双击创建的 CSV 文件即可。“`-UseCulture`”确保CSV使用正确的分隔符以便 Excel 打开它。
<!--本文国际来源：[Listing All Domain Controllers](https://blog.idera.com/database-tools/powershell/powertips/listing-all-domain-controllers/)-->

