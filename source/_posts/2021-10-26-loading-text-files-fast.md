---
layout: post
date: 2021-10-26 00:00:00
title: "PowerShell 技能连载 - 读取文本文件（快速）"
description: PowerTip of the Day - Loading Text Files (Fast)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您需要加载大文本文件并使用 `Get-Content`，那么您可以节省大量时间。

如果您没有立即通过管道处理通过管道发出的结果，则可能需要添加参数 `-ReadCount 0`。这可以使读取文本文件的速度提升 100 倍。

如果没有此参数，`Get-Content` 会单独对每个文本行产生一次输出。如果这些行要传递给管道处理，那么没有问题。但是如果要将文本存储在变量中并使用其他处理方式，则这是浪费时间，例如经典的 `foreach` 循环。

<!--本文国际来源：[Loading Text Files (Fast)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/loading-text-files-fast)-->

