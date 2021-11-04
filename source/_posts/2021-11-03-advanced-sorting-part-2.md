---
layout: post
date: 2021-11-03 00:00:00
title: "PowerShell 技能连载 - 高级排序（第 2 部分）"
description: PowerTip of the Day - Advanced Sorting (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`Sort-Object` 支持高级排序，并在您传入哈希表时提供更多控制。例如，哈希表可以单独控制多个属性的排序方向。

例如，此行代码按状态对服务进行排序，然后按名称排序。排序方向可以通过 `-Descending` 开关参数控制，但始终适用于所有选定的属性：

```powershell
Get-Service | Sort-Object -Property Status, DisplayName | Select-Object -Property DisplayName, Status

Get-Service | Sort-Object -Property Status, DisplayName -Descending | Select-Object -Property DisplayName, Status
```

要单独控制排序方向，请传入哈希表并使用 `Expression` 和 `Descending` 键。这首先按状态（降序）对服务进行排序，然后按显示名称（升序）：

```powershell
Get-Service |
Sort-Object -Property @{Expression='Status'; Descending=$true}, @{Expression='DisplayName'; Descending=$false } |
Select-Object -Property DisplayName, Status
```

注意：当您查看结果时，您可能会对“状态”属性的内容排序方式感到恼火。尽管代码要求降序排序，但您首先会看到正在运行的服务，然后是停止的服务。

这个问题的简单答案是：您现在知道如何单独控制排序，因此如果排序顺序错误，只需尝试颠倒排序顺序，看看是否适合您。

深入的答案是："`Status`" 属性实际上是一个数字常量，而 `Sort-Object` 始终对底层数据进行排序。因此，当您使数字常量可见时，会发现排序顺序是正确的：

```powershell
Get-Service |
Sort-Object -Property @{Expression='Status'; Descending=$true}, @{Expression='DisplayName'; Descending=$false } |
Select-Object -Property DisplayName, { [int]$_.Status }
```

正如您现在所看到的，"`Running`" 实际上是常量 "4"，而 "Stopped" 由常量 1 表示。

不要错过我们的下一个技能，以获得更多控制（以及对由底层数字常量引起的问题的优雅修复）。

<!--本文国际来源：[Advanced Sorting (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/advanced-sorting-part-2)-->

