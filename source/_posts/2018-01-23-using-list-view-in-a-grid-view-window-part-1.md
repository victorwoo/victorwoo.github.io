---
layout: post
date: 2018-01-23 00:00:00
title: "PowerShell 技能连载 - 用网格视图窗口显示列表视图（第 1 部分）"
description: PowerTip of the Day - Using List View in a Grid View Window (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
一个最简单的硬件清单功能可以用一行代码实现：

```powershell
$data = systeminfo.exe /FO CSV | ConvertFrom-Csv
$data | Out-GridView
```

一个更现代的方法是使用新的 `Get-ComputerInfo` cmdlet：

```powershell
$data = Get-ComputerInfo
$data | Out-GridView
```

一个最简单方法是用 `Group-Object 创建一个哈希表：将原始数据用某个属性，例如 `UserName` 来分组。然后，在网格视图窗口中显示哈希表的键。当用户选择了一个对象时，将选中的项目作为哈希表的键，找到原始项目：

```powershell
$data = Get-ComputerInfo
    
$data | 
    Get-Member -MemberType *Property | 
    Select-Object -ExpandProperty Name |
    ForEach-Object { $hash = @{}} { $hash[$_] = $data.$_ } { $hash } |
    Out-GridView
```

现在网格视图窗口以更好的方式显示信息。这段代码用 `Get-Member` 来查找信息对象 `$data` 中暴露的属性名。它接下来创建一个哈希表，每个属性代表一个键，每个值代表一个属性值。

本质上，网格视图窗口现在显示的是多个键值对，而不是单一的一个对象。

<!--本文国际来源：[Using List View in a Grid View Window (Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/using-list-view-in-a-grid-view-window-part-1)-->
