---
layout: post
date: 2019-04-23 00:00:00
title: "PowerShell 技能连载 - 使用变量断点（第 2 部分）"
description: PowerTip of the Day - Using Variable Breakpoints (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们试验了用 `Set-PSBreakpoint` 在 PowerShell 中创建动态变量断点。我们演示了当一个变量改变时，如何触发一个断点。

然而，如果您希望监视对象的属性呢？假设您希望监视数组的大小，当数组元素变多时自动进入调试器。

在这个场景中，PowerShell 变量并没有改变。实际上是变量中的对象发生了改变。所以您需要一个“读”模式的断点而不是一个“写”模式的断点：

```powershell
# break when $array’s length is greater than 10
Set-PSBreakpoint -Variable array -Action { if ($array.Length -gt 10) { break }} -Mode Read -Script $PSCommandPath

$array = @()
do
{
    $number = Get-Random -Minimum -20 -Maximum 20
    "Adding $number to $($array.count) elements"
    $array += $number

} while ($true)
```

当 `$array` 数组的元素超过 10 个时，脚本会中断下来并进入调试器。别忘了按 `SHIFT`+`F5` 退出调试器。

<!--本文国际来源：[Using Variable Breakpoints (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-variable-breakpoints-part-2)-->

