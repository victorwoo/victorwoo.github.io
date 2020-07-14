---
layout: post
date: 2020-06-25 00:00:00
title: "PowerShell 技能连载 - 在网格视图窗口中将对象数据显示为表格"
description: PowerTip of the Day - Showing Object Data as Table in a Grid View Window
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
通常，当将单个对象输出到 Out-GridView 时，将得到一行数据，并且每个属性都以一列的形式出现：

```powershell
Get-ComputerInfo | Select-Object -Property * | Out-GridView
```

这样难以查看和过滤特定信息。只需将对象转换为有序哈希表，即可将其显示为网格视图窗口中的表。此外，您现在还可以消除空属性并确保对属性进行排序：

```powershell
# make sure you have exactly ONE object
$info = Get-ComputerInfo
# find names of non-empty properties
$filledProperties = $info.PSObject.Properties.Name.Where{![string]::IsNullOrWhiteSpace($info.$_)} | Sort-Object
# turn object into a hash table and show in a grid view window
$filledProperties | ForEach-Object { $hash = [Ordered]@{} } { $hash[$_] = $info.$_ } { $hash } | Out-GridView
```

只要 `$info` 恰好包含一个对象，该方法就可以完美地工作。例如，您可以调整代码，并使用 "`Get-AdUser -Identify SomeName -Properties *`" 代替 "`Get-ComputerInfo`" 来列出给定用户的所有 Active Directory 属性。只要确保您精确地指定了一个用户即可。

由于此方法将对象转换为键值对，因此不适用于多个对象。

<!--本文国际来源：[Showing Object Data as Table in a Grid View Window](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/showing-object-data-as-table-in-a-grid-view-window)-->

