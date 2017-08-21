---
layout: post
date: 2017-08-10 00:00:00
title: "PowerShell 技能连载 - 创建 HTML 报表（第二部分 - 修复非字符串内容）"
description: "PowerTip of the Day - Creating HTML Reports (Part 2 – Fixing Non-String Content)"
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
在前一个技能中我们开始使用 PowerShell 来将结果转换为 HTML 报告。目前，我们已经生成了报告，但报告的界面看起来很丑。我们从这里开始：

```powershell
#requires -Version 2.0

$Path = "$env:temp\eventreport.htm"
$startDate = (Get-Date).AddHours(-48)

Get-EventLog -LogName System -EntryType Error -After $startDate |
    Select-Object -Property EventId, Message, Source, InstanceId, TimeGenerated, ReplacementStrings, UserName |
    ConvertTo-Html |
    Set-Content -Path $Path

Invoke-Item -Path $Path
```

当您运行这段代码时，报告显示有一些属性包含非字符串内容。请看 "ReplacementStrings" 列：报告中含有 `string[]`，也就是字符串数组类型，而不是真实数据。

要修复这个问题，请使用计算属性，并且将内容转换为可读的文本：

```powershell
#requires -Version 2.0

$Path = "$env:temp\eventreport.htm"
$startDate = (Get-Date).AddHours(-48)

# make sure the property gets piped to Out-String to turn its
# content into readable text that can be displayed in the report
$replacementStrings = @{
    Name = 'ReplacementStrings'
    Expression = { ($_.ReplacementStrings | Out-String).Trim() }
}

Get-EventLog -LogName System -EntryType Error -After $startDate |
    # select the properties to be included in your report
    Select-Object -Property EventId, Message, Source, InstanceId, TimeGenerated, $ReplacementStrings, UserName |
    ConvertTo-Html |
    Set-Content -Path $Path

Invoke-Item -Path $Path
```

如您所见，该属性现在能正常显示它的内容了。

要如何将属性内容转换成可读的文本依赖于您的选择。如果将属性通过管道传给 `Out-String`，将把转换工作留给 PowerShell 自动完成。如果您希望更精细的控制，而且某个属性包含一个数组，您也可以使用 `-join` 操作符来连接数组元素。通过这种方式，您可以选择使用哪种分隔符来分割数组元素。以下例子使用逗号分隔：

```powershell
#requires -Version 2.0

$Path = "$env:temp\eventreport.htm"
$startDate = (Get-Date).AddHours(-48)

# make sure the property gets piped to Out-String to turn its
# content into readable text that can be displayed in the report
$replacementStrings = @{
    Name = 'ReplacementStrings'
    Expression = { $_.ReplacementStrings -join ',' }
}

Get-EventLog -LogName System -EntryType Error -After $startDate |
    # select the properties to be included in your report
    Select-Object -Property EventId, Message, Source, InstanceId, TimeGenerated, $ReplacementStrings, UserName |
    ConvertTo-Html |
    Set-Content -Path $Path

Invoke-Item -Path $Path
```
<!--more-->
本文国际来源：[Creating HTML Reports (Part 2 – Fixing Non-String Content)](http://community.idera.com/powershell/powertips/b/tips/posts/creating-html-reports-part-2-fixing-non-string-content)
