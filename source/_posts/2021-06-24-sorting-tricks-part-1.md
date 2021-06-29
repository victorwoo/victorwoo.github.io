---
layout: post
date: 2021-06-24 00:00:00
title: "PowerShell 技能连载 - 排序技巧（第 1 部分）"
description: PowerTip of the Day - Sorting Tricks (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`Sort-Object` 是用于排序的 cmdlet：只需指定要排序的属性，`Sort-Object` 涵盖其余部分，包括根据属性数据类型选择正确的排序算法：

```powershell
Get-Service | Sort-Object -Property DisplayName -Descending
```

一个鲜为人知的事实是 `Sort-Object` 也接受哈希表，这给了你更多的控制权。例如，您可以像这样轻松地对多个属性进行排序：

```powershell
Get-Service | Sort-Object -Property Status, DisplayName -Descending
```

但是，如果您想控制每个属性的排序方向，则需要一个哈希表。此示例按降序对状态进行排序，但按升序对显示名称进行排序：

```powershell
$displayName = @{
    Expression = "DisplayName"
    Descending = $false
}

Get-Service | Sort-Object -Property Status, $displayName -Descending
```

<!--本文国际来源：[Sorting Tricks (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/sorting-tricks-part-1)-->

