---
layout: post
date: 2018-10-25 00:00:00
title: "PowerShell 技能连载 - 通过 PowerShell 调用 Excel 宏"
description: PowerTip of the Day - Invoking Excel Macros from PowerShell
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
PowerShell 可以调用 Microsoft Excel 工作表，并执行其中的宏。由于这只对可见的 Excel 程序窗口有效，所以当您尝试进行安全敏感操作，例如宏时，最好保持 Excel 打开（参见以下代码）来查看警告信息：

```powershell
# file path to your XLA file with macros
$FilePath = "c:\test\file.xla"
# macro name to run
$Macro = "AddData"

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $true
$wb = $excel.Workbooks.Add($FilePath)
$excel.Run($Macro)
```

<!--more-->
本文国际来源：[Invoking Excel Macros from PowerShell](http://community.idera.com/powershell/powertips/b/tips/posts/invoking-excel-macros-from-powershell)
