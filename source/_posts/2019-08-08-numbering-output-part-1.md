---
layout: post
date: 2019-08-08 00:00:00
title: "PowerShell 技能连载 - 为输出编号（第 1 部分）"
description: PowerTip of the Day - Numbering Output (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果你想增加一个递增的数字到你的输出，这里有一个简单的方法:

```powershell
Get-Process |
  Select-Object -Property '#', ProcessName, CPU -First 10 |
  ForEach-Object -begin { $i = 0} -process {
    $i++
    $_.'#' = $i
    $_
  } -end {}
```

`Select-Object` 添加了一个名为 "`#`" 的新属性，`ForEach-Object` 添加了一个自动递增的数字。结果如下：

     # ProcessName               CPU
     - -----------               ---
     1 AdobeCollabSync       65,5625
     2 AdobeCollabSync           0,5
     3 AGMService
    ...

<!--本文国际来源：[Numbering Output (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/numbering-output-part-1)-->

