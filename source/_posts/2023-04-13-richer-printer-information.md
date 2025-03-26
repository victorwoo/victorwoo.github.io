---
layout: post
date: 2023-04-13 00:40:07
title: "PowerShell 技能连载 - 更丰富的打印机信息"
description: PowerTip of the Day - Richer Printer Information
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`Get-Printer` 返回所有本地打印机的基本信息。当您添加开关参数 `-Full` 时，它会返回更详细的信息，例如打印机权限，但乍一看，无论是否指定了 `-Full`，`Get-Printer` 似乎输出相同的信息。

要查看增强信息，必须要求 PowerShell 显示所有属性，因为默认情况下所有增强属性都是隐藏的。以下代码揭示了通过指定 -Full 所做出的差异：

```powershell
Get-Printer | Select-Object -Property * | Out-GridView -Title 'Without -Full'
Get-Printer -Full | Select-Object -Property * | Out-GridView -Title 'With -Full'
```

最显著的区别在于 PermissionSDDL 属性。

<!--本文国际来源：[Richer Printer Information](https://blog.idera.com/database-tools/powershell/powertips/richer-printer-information/)-->

