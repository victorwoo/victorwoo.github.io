---
layout: post
date: 2019-07-31 00:00:00
title: "PowerShell 技能连载 - 控制处理器关联性"
description: PowerTip of the Day - Controlling Processor Affinity
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
大多数现代计算机都有不止一个处理器，无论是物理处理器还是逻辑处理器。如果你想知道处理器的数量，这里有一段 PowerShell 代码:

```powershell
Get-WmiObject -Class Win32_Processor |
    Select-Object -Property Caption, NumberOfLogicalProcessors
```

结果看起来类似这样：

    Caption                              NumberOfLogicalProcessors
    -------                              -------------------------
    Intel64 Family 6 Model 78 Stepping 3                         4

当您在这样的机器上运行一个进程时，它通常没有特定的处理器关联性，因此 Windows 决定该进程将运行在哪个处理器上。

如果愿意，可以为每个进程声明一个特定的处理器关联。这是很有用的，例如，如果你想控制一个程序可以使用的处理器，也就是防止一个进程使用所有的处理器。

处理器关联性由位标志控制。要找出当前处理器与进程的关联关系，请使用以下代码:

```powershell
$process = Get-Process -Id $PID
[Convert]::ToString([int]$process.ProcessorAffinity, 2)
```

在本例中，用的是当前的 PowerShell 进程，但是您可以指定任何进程。典型的结果是:

    1111

在 4 处理器的机器上，进程没有特定的关联性，可以使用任何处理器。要设置新的关联，最简单的方法是使用自己的位掩码并更改属性。例如，要将当前 PowerShell 进程仅锁定到第一个处理器，可以这样做:

```powershell
# calculate the bit mask
$mask = '1000'
$bits = [Convert]::ToInt32($mask, 2)

# assign new affinity to current PowerShell process
$process = Get-Process -Id $PID
$process.ProcessorAffinity = $bits
```

<!--本文国际来源：[Controlling Processor Affinity](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/controlling-processor-affinity)-->

