---
layout: post
date: 2023-01-25 06:00:51
title: "PowerShell 技能连载 - 研究 PowerShell 命令结果"
description: PowerTip of the Day - Investigating PowerShell Command Results
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
HTML 是一种简单的格式化输出报告的方法。在这个三部曲系列中，我们首先演示如何生成 HTML 报告，然后展示一种简单的方法将 HTML 报告转为 PDF 文档。

一个简单的研究命令返回结果的方法是使用 `Select-Object` 显示第一个（随机的）返回结果的所有属性。以下是一个例子：

```powershell
Get-Service | Select-Object -Property * -First 1
```

通过这种方法，您可以获得一个返回结果，它的所有属性都可见，并且您可以看见这些属性中的实际数值来更好地评估要使用哪些属性。

另一个研究的方法是使用 `Get-Member` 从更偏技术/定义的角度查看所有可用的属性:

···powershell
Get-Service | Get-Member -MemberType *property
```

现在，您可以查看所有返回的数据类型，以及每个定义为 "`{get;}`"（只读）或 "`{get;set;}`"（读写）的属性。
<!--本文国际来源：[Investigating PowerShell Command Results](https://blog.idera.com/database-tools/powershell/powertips/investigating-powershell-command-results/)-->

