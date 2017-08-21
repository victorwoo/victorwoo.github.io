---
layout: post
date: 2017-08-14 00:00:00
title: "PowerShell 技能连载 - 创建 HTML 报表（第四部分 - 重命名列）"
description: "PowerTip of the Day - Creating HTML Reports (Part 4 – Renaming Columns)"
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
在之前的技能中我们开始将 PowerShell 结果转为 HTML 报告。现在报告的结果接近完成了。我们只需要对某些列标题进行润色和重命名即可。这是上一次的脚本：

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

要重命名列标题，请使用之前同样的策略将非字符串内容转换为字符串内容：使用计算属性。所以如果您想将 `TimeGenerated` 重命名为 `Time`，那么可以这样做：

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
    # specify NEW name for column (property)
    Name = 'Time'
    # use existing value
    Expression = { $_.TimeGenerated }
}

Get-EventLog -LogName System -EntryType Error -After $startDate |
    Select-Object -Property EventId, Message, Source, InstanceId, $TimeGenerated, $ReplacementStrings, UserName |
    ConvertTo-Html -PreContent $preContent -PostContent $postContent |
    Set-Content -Path $Path

Invoke-Item -Path $Path
```

<!--more-->
本文国际来源：[Creating HTML Reports (Part 4 – Renaming Columns)](http://community.idera.com/powershell/powertips/b/tips/posts/creating-html-reports-part-4-renaming-columns)
