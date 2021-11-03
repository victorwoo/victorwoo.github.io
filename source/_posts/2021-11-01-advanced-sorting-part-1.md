---
layout: post
date: 2021-11-01 00:00:00
title: "PowerShell 技能连载 - 高级排序（第 1 部分）"
description: PowerTip of the Day - Advanced Sorting (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Sort-Object easily sorts results for you. For primitive data such as numbers or strings, simply add Sort-Object to your pipeline. This gets you a sorted list of lottery numbers:
`Sort-Object` 能轻松对结果排序。对于数字或字符串等原始数据，只需将 `Sort-Object` 添加到您的管道中。这将为您提供一个排序的彩票号码列表：

```powershell
$lottery = 1..49 | Get-Random -Count 7 | Sort-Object
# set the string you want to use to separate numbers in your output
$ofs = ','
"Your numbers are $lottery"
```

具有多个属性的对象数据要求您定义要排序的属性。此行代码按状态对服务进行排序：

```powershell
Get-Service | Sort-Object -Property Status
```

`Sort-Object` 甚至支持多种排序。此行代码按状态对服务进行排序，然后按服务名称排序：

```powershell
Get-Service | Sort-Object -Property Status, DisplayName | Select-Object -Property DisplayName, Status
```

要反转排序顺序，请添加 `-Descending` 开关参数。

有关排序的更多控制，例如，对一个属性升序排序和另一个属性降序排序，请参阅我们的下一个提示。

<!--本文国际来源：[Advanced Sorting (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/advanced-sorting-part-1)-->

