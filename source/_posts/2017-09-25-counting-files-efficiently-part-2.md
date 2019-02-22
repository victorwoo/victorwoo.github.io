---
layout: post
date: 2017-09-25 00:00:00
title: "PowerShell 技能连载 - 高效统计文件数量（第二部分）"
description: PowerTip of the Day - Counting Files Efficiently (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们学习了如何有效地统计一个文件夹中项目的数量。以下是更多的例子。

用 PowerShell 统计指定文件夹中文件的数量易如反掌：

```powershell
$count = Get-ChildItem -Path "$home\Desktop" -Force |
  Measure-Object |
  Select-Object -ExpandProperty Count

"Number of files: $Count"
```

只需要调整 `Get-ChildItem` 的参数就可以找到更多。例如添加 `-Recurse` 开关，就可以包括子文件夹中的文件：

```powershell
$count = Get-ChildItem -Path "$home\Desktop" -Force -Recurse -ErrorAction SilentlyContinue  |
  Measure-Object |
  Select-Object -ExpandProperty Count

"Number of files: $Count"
```

或者，只关注某些文件。这个例子只统计两层目录深度以内的 log 和 txt 文件：

```powershell
$count = Get-ChildItem -Path $env:windir -Force -Recurse -Include *.log, *.txt -ErrorAction SilentlyContinue -Depth 2 |
  Measure-Object |
  Select-Object -ExpandProperty Count

"Number of files: $Count"
```

（请注意：`-Depth` 参数是 PowerShell 5 引入的）

<!--本文国际来源：[Counting Files Efficiently (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/counting-files-efficiently-part-2)-->
