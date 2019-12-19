---
layout: post
date: 2019-12-10 00:00:00
title: "PowerShell 技能连载 - Foreach -parallel (第 2 部分：Windows PowerShell)"
description: 'PowerTip of the Day - Foreach -parallel (Part 2: Windows PowerShell)'
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 7 发布了一个内置参数，可以并行运行不同的任务：

```powershell
    1..100 | ForEach-Object -ThrottleLimit 20 -Parallel { Start-Sleep -Seconds 1; $_ }
```

如果您使用的是 Windows PowerShell，那么您也可以使用类似的并行技术。例如，下载并安装这个免费的模块：

```powershell
Install-Module -Name PSParallel -Scope CurrentUser -Force
```

它带来一个新的命令：`Invoke-Parallel`：您可以这样使用它：

```powershell
1..100 | Invoke-Parallel -ThrottleLimit 20 -Scrip-tBlock { Start-Sleep -Seconds 1; $_ }
```

由于 `Invoke-Parallel` 使用的是和 PowerShell 7 相同的技术，所以有相同的限制：每个线程都在它自己的线程中执行，并且不能存取本地变量。在下一个技能中，我们将学习一些有趣的示例。

<!--本文国际来源：[Foreach -parallel (Part 2: Windows PowerShell)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/foreach--parallel-part-2-windows-powershell)-->

