---
layout: post
date: 2019-12-06 00:00:00
title: "PowerShell 技能连载 - Foreach -parallel（第 1 部分：PowerShell 7）"
description: 'PowerTip of the Day - Foreach -parallel (Part 1: PowerShell 7)'
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 7 发布了一个内置参数，可以并行运行不同的任务。以下是一个简单示例：

```powershell
    1..100 | ForEach-Object -ThrottleLimit 20 -Parallel { Start-Sleep -Seconds 1; $_ }
```

在普通的 `ForEach-Object` 循环中，这将花费 100 秒的时间执行。如果使用了 `parallel`，代码可以并行地执行。`-ThrottleLimit` 定义了“块”，因此在本例中，有20个线程并行运行，使总执行时间减少到5秒。

在过于激动之前，请记住每个线程都在其自己的 PowerShell 环境中运行。幸运的是，您可以访问前缀为“`using:`”的局部变量：

```powershell
    $text = "Output: "

    1..100 | ForEach-Object -ThrottleLimit 20 -Parallel { Start-Sleep -Seconds 1; "$using:text $_" }
```

不过，当您开始使用多线程时，您需要了解线程安全知识。复杂对象，例如 `ADUser` 对象可能无法在多个线程之间共享，所以需要每个案例独立判断是否适合使用并行。

由于并行的 `ForEach-Object` 循环内置在 PowerShell 7 中，这并不意味着可以在 Windows PowerShell 中使用并行。在 Windows PowerShell 中有许多模块实现了该功能。我们将会在接下来的技能中介绍它们。

<!--本文国际来源：[Foreach -parallel (Part 1: PowerShell 7)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/foreach--parallel-part-1-powershell-7)-->

