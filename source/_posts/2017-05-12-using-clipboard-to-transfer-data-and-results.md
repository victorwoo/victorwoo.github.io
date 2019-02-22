---
layout: post
date: 2017-05-12 00:00:00
title: "PowerShell 技能连载 - 使用剪贴板来传输数据和结果"
description: PowerTip of the Day - Using Clipboard to Transfer Data and Results
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
终于，在 PowerShell 5 中原生支持将结果发送到剪贴板中，以及从剪贴板中接收结果：

```powershell
PS> Get-Command -Noun Clipboard 

CommandType Name          Version Source                         
----------- ----          ------- ------                         
Cmdlet      Get-Clipboard 3.1.0.0 Microsoft.PowerShell.Management
Cmdlet      Set-Clipboard 3.1.0.0 Microsoft.PowerShell.Management
```     

例如，您可以打开一个包含一些数据的 Excel 表格，将一列复制到剪贴板中，然后在 PowerShell 中进一步处理数据，例如过滤它：

```powershell     
PS> $list = (Get-ClipBoard) -like '*err*'
```

<!--本文国际来源：[Using Clipboard to Transfer Data and Results](http://community.idera.com/powershell/powertips/b/tips/posts/using-clipboard-to-transfer-data-and-results)-->
