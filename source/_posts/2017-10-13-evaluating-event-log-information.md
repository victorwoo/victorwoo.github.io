---
layout: post
date: 2017-10-13 00:00:00
title: "PowerShell 技能连载 - 评价事件日志信息"
description: PowerTip of the Day - Evaluating Event Log Information
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`Get-EventLog` 可以访问传统的 Windows 事件日志写入的内容。可以在一个名为 `ReplacementStrings` 的属性中找到最有价值的信息。以下是一个使该信息可视化并且可以利用它来生成报告的方法。

在这个例子中，将获取 Windows Update 客户端写入的 ID 为 44 的事件，并且这段代码输出替换的字符串。它们将精确地告知我们何时下载了哪些更新：

```powershell
Get-EventLog -LogName System -InstanceId 44 -Source Microsoft-Windows-WindowsUpdateClient |
ForEach-Object {

  $hash = [Ordered]@{}
  $counter = 0
  foreach($value in $_.ReplacementStrings)
  {
    $counter++
    $hash.$counter = $value
  }
  $hash.EventID = $_.EventID
  $hash.Time = $_.TimeWritten
  [PSCustomObject]$hash


  }
```

始终确保查询一个唯一的事件 ID：对于每个事件 ID，ReplacementStrings 中的信息是唯一的，您一定不希望将不同的事件 ID 类型中的信息混在一起。

<!--本文国际来源：[Evaluating Event Log Information](http://community.idera.com/powershell/powertips/b/tips/posts/evaluating-event-log-information)-->
