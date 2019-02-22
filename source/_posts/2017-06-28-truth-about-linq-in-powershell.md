---
layout: post
date: 2017-06-28 00:00:00
title: "PowerShell 技能连载 - PowerShell 中 LINQ 的真实情况"
description: PowerTip of the Day - Truth about LINQ in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
不久前有一些关于 LINQ，一个 .NET 查询语言，在 PowerShell 中用来提升代码速度的报告。

直到 PowerShell 真正支持 Linq 之前，使用 Linq 是非常冗长的，并且需要使用强类型和没有文档的方法。另外，同样的事可以使用纯 PowerShell 方法来做，速度的提升很少——至少对 IPPro 相关的任务不明显。

以下是一个使用很简单的 Linq 语句对数字求和的测试用例。它接受 Windows 文件夹下的所有文件，然后对所有文件的长度求和：

```powershell
$numbers = Get-ChildItem -Path $env:windir -File | Select-Object -ExpandProperty Length

(Measure-Command {
  $sum1 = [Linq.Enumerable]::Sum([int[]]$numbers)
}).TotalMilliseconds

(Measure-Command {
  $sum2 = ($numbers | Measure-Object -Sum).Sum
}).TotalMilliseconds

(Measure-Command {
  $sum3 = 0
  foreach ($number in $numbers) { $sum3+=$number }
}).TotalMilliseconds
```

当您运行它多次的时候，您会观察到执行时间的输出。Linq 的方法可以使用，但是对数据类型十分敏感。例如，您需要将数字数组转换为 integer 数组，否则 Linq 的 `Sum()` 方法将不起作用。

可以提炼出两条法则：

1. 这时不值得使用 Linq，因为它尚未集成到 PowerShell 中，并且会产生难读的代码。它几乎相当于在 PowerShell 使用 C# 源代码。

1. 如果您想提升速度，请在所有可能的地方避免使用管道。foreach 循环的执行速度比用管道将许多对象通过管道传到 `ForEach-Object` 快许多。

If Linq was better integrated into PowerShell in the future, it would indeed be highly interesting.

<!--本文国际来源：[Truth about LINQ in PowerShell](http://community.idera.com/powershell/powertips/b/tips/posts/truth-about-linq-in-powershell)-->
