---
layout: post
date: 2017-08-09 00:00:00
title: "PowerShell 技能连载 - 创建 HTML 报表（第一部分 - 创建 HTML）"
description: "PowerTip of the Day - Creating HTML Reports (Part 1 – Creating HTML)"
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
要将 PowerShell 的处理结果输出为 HTML 报表，只需要将结果用管道传给 `ConvertTo-Html`，然后将结果保存到文件。所以它最基本的使用形式类似如下。它创建一个包含过去 48 小时发生的所有事件系统错误的报表：

```powershell
#requires -Version 2.0

# store report here
$Path = "$env:temp\eventreport.htm"
# set the start date
$startDate = (Get-Date).AddHours(-48)

# get data and convert it to HTML
Get-EventLog -LogName System -EntryType Error -After $startDate |
  ConvertTo-Html |
  Set-Content -Path $Path

# open the file with associated program
Invoke-Item -Path $Path 
```

不过，输出的报告可能有点丑，因为包含了许多无用的信息。所以美化的第一步是选择报告中需要的属性。只需要在代码中加入 `Select-Object`：

```powershell
#requires -Version 2.0

$Path = "$env:temp\eventreport.htm"
$startDate = (Get-Date).AddHours(-48)

Get-EventLog -LogName System -EntryType Error -After $startDate |
  # select the properties to be included in your report
  Select-Object -Property EventId, Message, Source, InstanceId, TimeGenerated, ReplacementStrings, UserName |
  ConvertTo-Html |
  Set-Content -Path $Path

Invoke-Item -Path $Path
```

<!--more-->
本文国际来源：[Creating HTML Reports (Part 1 – Creating HTML)](http://community.idera.com/powershell/powertips/b/tips/posts/creating-html-reports-part-1-creating-html)
