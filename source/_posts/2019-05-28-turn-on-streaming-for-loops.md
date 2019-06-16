---
layout: post
date: 2019-05-28 00:00:00
title: "PowerShell 技能连载 - 对循环启用流操作"
description: PowerTip of the Day - Turn on Streaming for Loops
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 包含许多循环构造。这些循环构造不能变成流，所以您无法将结果通过管道传递给其它 cmdlet 并且享受管道的实时性优势。相反，您必须先将所有数据存储在变量中，并且只有当循环结束之后才可以将变量通过管道传递给其它命令。

虽然您可以用 `ForEach-Object` 来代替传统的 `foreach` 和 `for` 循环，但它会减慢代码的执行速度，并且不是代替 `while` 和 `do` 循环的方案。

以下是一个对所有循环启用快速流的简单技巧。让我们从这个非常简单的循环开始：

```powershell
# stupid sample using a do loop
# a more realistic use case could be a database query

do
{
  $val = Get-Random -Minimum 0 -Maximum 10
  $val

} while ($val -ne 6)
```

它会一直循环直到达到随机数 6。您会发现无法实时将结果传输到管道，所以你必须使用类似这样的方法来对结果进行排序或者用它们来做其他事情：

```powershell
$all = do
{
  $val = Get-Random -Minimum 0 -Maximum 10
  $val

} while ($val -ne 6)

$all | Out-GridView
```

通过将循环封装到一个脚本块中，您可以获得实时流：更少的内存消耗，立即得到结果：

```powershell
& { do
{
  $val = Get-Random -Minimum 0 -Maximum 10
  $val

} while ($val -ne 6) } | Out-GridView
```

<!--本文国际来源：[Turn on Streaming for Loops](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/turn-on-streaming-for-loops)-->

