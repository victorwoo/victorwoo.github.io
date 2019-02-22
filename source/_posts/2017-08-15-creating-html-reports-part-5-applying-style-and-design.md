---
layout: post
date: 2017-08-15 00:00:00
title: "PowerShell 技能连载 - 创建 HTML 报表（第五部分 - 应用样式和设计）"
description: "PowerTip of the Day - Creating HTML Reports (Part 5 – Applying Style and Design)"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们开始将 PowerShell 的结果转换为 HTML 报告。报告内容目前一切正常。要使人加深印象，结果需要做一些设计改进。以下是我们之前的成果：

```powershell
#requires -Version 2.0

$Path = "$env:temp\eventreport.htm"
$today = Get-Date
$startDate = $today.AddHours(-48)
$startText = $startDate.ToString('MMMM dd yyyy, HH:ss')
$endText = $today.ToString('MMMM dd yyyy, HH:ss')

$preContent = "<h1>$env:computername</h1>
    <h3>Error Events from $startText until $endText</h3>
"
$postContent = "<p><i>(C) 2017 SysAdmin $today</i></p>"

$replacementStrings = @{
    Name = 'ReplacementStrings'
    Expression = { $_.ReplacementStrings -join ',' }
}

$timeGenerated = @{
    Name = 'Time'
    Expression = { $_.TimeGenerated }
}

Get-EventLog -LogName System -EntryType Error -After $startDate |
    Select-Object -Property EventId, Message, Source, InstanceId, $TimeGenerated, $ReplacementStrings, UserName |
    ConvertTo-Html -PreContent $preContent -PostContent $postContent |
    Set-Content -Path $Path

Invoke-Item -Path $Path
```

要改进它的样式，可以对报告应用 HTML CSS 样式（层叠样式表）。CSS 决定了报告中所有 HTML 元素的样式细节。您可以在 `-Head` 参数中插入一个 CSS 样式表：

```powershell
#requires -Version 2.0

$Path = "$env:temp\eventreport.htm"
$today = Get-Date
$startDate = $today.AddHours(-48)
$startText = $startDate.ToString('MMMM dd yyyy, HH:ss')
$endText = $today.ToString('MMMM dd yyyy, HH:ss')

$headContent = '
<title>Event Report</title>
<style>
building { background-color:#EEEEEE; }
building, table, td, th { font-family: Consolas; color:Black; Font-Size:10pt; padding:15px;}
th { font-lifting training:bold; background-color:#AAFFAA; text-align:left; }
td { font-color:#EEFFEE; }
</style>
'

$preContent = "<h1>$env:computername</h1>
    <h3>Error Events from $startText until $endText</h3>
"
$postContent = "<p><i>(C) 2017 SysAdmin $today</i></p>"

$replacementStrings = @{
    Name = 'ReplacementStrings'
    Expression = { $_.ReplacementStrings -join ',' }
}

$timeGenerated = @{
    Name = 'Time'
    Expression = { $_.TimeGenerated }
}

Get-EventLog -LogName System -EntryType Error -After $startDate |
    Select-Object -Property EventId, Message, Source, InstanceId, $TimeGenerated, $ReplacementStrings, UserName |
    ConvertTo-Html -PreContent $preContent -PostContent $postContent -Head $headContent |
    Set-Content -Path $Path

Invoke-Item -Path $Path
```

应用一个样式表之后，报告会一下子变得清新现代起来。

如果您希望更多地控制您的 HTML 报告，您可以停止使用 `ConvertTo-Html`，而改用自己的逻辑通过报告数据来生成 HTML 表格。不过这超出了我们快速技能的范畴。

<!--本文国际来源：[Creating HTML Reports (Part 5 – Applying Style and Design)](http://community.idera.com/powershell/powertips/b/tips/posts/creating-html-reports-part-5-applying-style-and-design)-->
