---
layout: post
date: 2019-12-16 00:00:00
title: "PowerShell 技能连载 - 使用一个计时器来测量执行时间"
description: PowerTip of the Day - Using a StopWatch to Measure Execution Times
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有一些情况下您希望知道一段代码需要执行多长时间，例如返回统计或者对比代码，有许多方法可以测量命令，包括 `Measure-Command` cmdlet：

```powershell
$duration = Measure-Command -Expression {
    $result = Get-Hotfix
}

$time = $duration.TotalMilliseconds

'{0} results in {1:n1} milliseconds' -f $result.Count, $time
```

不过 `Measure-Command` 有一些不受人喜欢的副作用：

* 所有输出都被丢弃，这样输出数据不会影响测量时间，而且您无法控制这个行为
* 出于好几个原因，它会减慢您的代码执行，其中一个是 `Measure-Command` 在 dot-sourced 表达式中以一个独立的脚本快执行

所以，常常使用另一个技术，用的是 `Get-Date`，例如这样：

```powershell
$start = Get-Date
$result = Get-Hotfix
$end = Get-Date
$time = ($end - $start).TotalMilliseconds

'{0} results in {1:n1} milliseconds' -f $result.Count, $time
```

它可以有效工作，不过也有一些不受欢迎的副作用：

* 它产生更多的代码
* 当计算机处于睡眠或休眠状态，将会影响结果，因为计算机关闭的时间不应该计入统计时间

一个更简洁的解决方案是使用 .NET 的 stopwatch 对象，它产生的代码更少，并且不会减缓代码的执行，而且不受睡眠或休眠的影响：

```powershell
$stopwatch =  [system.diagnostics.stopwatch]::StartNew()
$result = Get-Hotfix
$time = $stopwatch.ElapsedMilliseconds

'{0} results in {1:n1} milliseconds' -f $result.Count, $time
```

此外，您可以对 stopwatch 对象调用 `Stop()`、`Restart()` 和 `Reset()` 方法。通过这些方法，您可以暂停测量代码中的某些部分（例如数据输出）并且继续测量。

<!--本文国际来源：[Using a StopWatch to Measure Execution Times](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-a-stopwatch-to-measure-execution-times)-->

