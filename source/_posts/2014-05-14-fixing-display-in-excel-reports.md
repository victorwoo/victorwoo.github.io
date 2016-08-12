layout: post
title: "PowerShell 技能连载 - 修正 Excel 报表中的显示"
date: 2014-05-14 00:00:00
description: PowerTip of the Day - Fixing Display in Excel Reports
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
当您发送信息到 Microsoft Excel 中时，它将被 .NET 内置的 `ToString()` 方法转化为文本。这个方法通常并不能正确地转化数组或非基本数据类型。

以下是一个例子演示这个问题。它创建了一个您系统事件日志中 10 个最近错误事件的报表：

    $Path = "$env:temp\$(Get-Random).csv"
    
    Get-EventLog -LogName System -EntryType Error -Newest 10 | 
      Select-Object EventID, MachineName, Data, Message, Source, ReplacementStrings, InstanceId, TimeGenerated |
      Export-Csv -Path $Path -Encoding UTF8 -NoTypeInformation -UseCulture
    
    Invoke-Item -Path $Path  

“Data”字段和“ReplacementStrings”无法使用。由于两个属性都包含数组，自动转换的结果只是简单显示数据的类型的名称。这是在从对象数据中创建 Excel 报表的常见现象。

要改进报表，您可以显式地使用 PowerShell 引擎将对象转化为文本，然后将多行文本转换为单行文本。

您可以对每个看起来不正确的字段运用这个方法。以下是上一个例子的解决方案，它能够改进 Message、Data 和 ReplacementStrings 字段的显示：

    $Path = "$env:temp\$(Get-Random).csv"
    
    Get-EventLog -LogName System -EntryType Error -Newest 10 | 
      Select-Object EventID, MachineName, Data, Message, Source, ReplacementStrings, InstanceId, TimeGenerated |
      ForEach-Object {
        $_.Message = ($_.Message | Out-String -Stream) -join ' '
        $_.Data = ($_.Data | Out-String -Stream) -join ', '
        $_.ReplacementStrings = ($_.ReplacementStrings | Out-String -Stream) -join ', '
    
        $_
      } |
      Export-Csv -Path $Path -Encoding UTF8 -NoTypeInformation -UseCulture
    
    Invoke-Item -Path $Path 
    
现在所有字段都显示了正确的结果。请注意有问题的属性首先通过管道发送到 `Out-String` 命令（用 PowerShell 内部的机制将数据转换为有意义的文本），然后用 `-join` 将信息连接成单行文本。

还请注意“Message”属性是如何处理的。虽然这个属性看起来没问题，但是它实际上有可能是多行文本。多行信息在 Excel 中将只显示第一行，并以“...”结尾。我们将这些行通过空格连接之后，Excel 便可以显示完整信息了。

<!--more-->
本文国际来源：[Fixing Display in Excel Reports](http://powershell.com/cs/blogs/tips/archive/2014/05/14/fixing-display-in-excel-reports.aspx)
