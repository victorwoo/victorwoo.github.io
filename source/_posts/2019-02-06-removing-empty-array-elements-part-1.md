---
layout: post
date: 2019-02-06 00:00:00
title: "PowerShell 技能连载 - 移除空的数组元素（第 1 部分）"
description: PowerTip of the Day - Removing Empty Array Elements (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
有些时候您会遇到包含空元素的列表（数组）。那么移除空元素的最佳方法是？

让我们首先关注一个普遍的场景：以下代码从注册表读取已安装的软件并创建一个软件清单。该软件清单将显示在一个网格视图窗口中，而很可能能看到包含空属性的元素：

```powershell
$Paths = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'

$software = Get-ItemProperty -Path $paths -ErrorAction Ignore |
  Select-Object -Property DisplayName, DisplayVersion, UninstallString

$software | Out-GridView
```

让我们忽略所有显示名称为空的元素：

```powershell
# remove elements with empty DisplayName property
$software = $software | Where-Object { [string]::IsNullOrWhiteSpace($_.DisplayName)}
```

由于空属性既包含“真正”为空 (`$null`) 也包含空字符串 (`''`)，您需要检查它们两者。更简单的方法是将它们隐式转换为 `Boolean`。然而，这样做仍然会移除数值 0:

```powershell
# remove elements with empty DisplayName property
$software = $software | Where-Object { $_.DisplayName }
```

使用 PowerShell 3 引入的简化语法，您甚至可以这样写：

```powershell
# remove elements with empty DisplayName property
$software = $software | Where-Object DisplayName
```

如果你想节省几毫秒，请使用 `where` 方法：

```powershell
# remove elements with empty DisplayName property
$software = $software.Where{ $_.DisplayName }
```

如果您想处理一个大数组，用 `foreach` 循环更有效（效率提升 15 倍）：

```powershell
# remove elements with empty DisplayName property
$software = foreach ($_ in $software){ if($_.DisplayName) { $_ }}
```

<!--more-->
本文国际来源：[Removing Empty Array Elements (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/removing-empty-array-elements-part-1)
