---
layout: post
date: 2017-08-11 00:00:00
title: "PowerShell 技能连载 - 创建 HTML 报表（第三部分 - 增加头部和尾部）"
description: "PowerTip of the Day - Creating HTML Reports (Part 3 – Adding Headers and Footers)"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们开始将 PowerShell 的结果转换为 HTML 报告。现在，这份报告需要一些头部和尾部。以下是我们上一个版本的代码：

```powershell
#requires -Version 2.0

$Path = "$env:temp\eventreport.htm"
$startDate = (Get-Date).AddHours(-48)

$replacementStrings = @{
    Name = 'ReplacementStrings'
    Expression = { $_.ReplacementStrings -join ',' }
}

Get-EventLog -LogName System -EntryType Error -After $startDate |
    Select-Object -Property EventId, Message, Source, InstanceId, TimeGenerated, $ReplacementStrings, UserName |
    ConvertTo-Html |
    Set-Content -Path $Path

Invoke-Item -Path $Path
```

要在数据前后加入内容，请使用 `-PreContent` 和 `-PostContent` 参数。比如在头部加入机器名，在尾部加入版权信息，请使用以下代码：

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

Get-EventLog -LogName System -EntryType Error -After $startDate |
    Select-Object -Property EventId, Message, Source, InstanceId, TimeGenerated, $ReplacementStrings, UserName |
    ConvertTo-Html -PreContent $preContent -PostContent $postContent |
    Set-Content -Path $Path

Invoke-Item -Path $Path
```

<!--本文国际来源：[Creating HTML Reports (Part 3 – Adding Headers and Footers)](http://community.idera.com/powershell/powertips/b/tips/posts/creating-html-reports-part-3-adding-headers-and-footers)-->
