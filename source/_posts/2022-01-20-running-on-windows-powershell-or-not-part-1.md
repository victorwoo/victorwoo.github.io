---
layout: post
date: 2022-01-20 00:00:00
title: "PowerShell 技能连载 - 是否在 Windows PowerShell 中运行（第 1 部分）"
description: "PowerTip of the Day - Running on Windows PowerShell – Or Not? (Part 1)"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
现在的 PowerShell 可以在各种平台上运行，并且在上一个技能中，我们解释了如何查看脚本运行的操作系统。

如果操作系统是 Windows，您仍然不能知道您的脚本是由内置 Windows PowerShell 还是新的便携式 PowerShell 7 运行。

以下是一种安全和向后兼容的方式，可以了解您的脚本是否在 Windows PowerShell 上运行：

```powershell
$RunOnWPS = !($PSVersionTable.ContainsKey('PSEdition') -and
                $PSVersionTable.PSEdition -eq 'Core')

"Runs on Windows PowerShell? $RunOnWPS"
```

<!--本文国际来源：[Running on Windows PowerShell – Or Not? (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/running-on-windows-powershell-or-not-part-1)-->

