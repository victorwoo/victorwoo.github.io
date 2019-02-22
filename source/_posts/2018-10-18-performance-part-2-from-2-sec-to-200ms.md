---
layout: post
date: 2018-10-18 00:00:00
title: "PowerShell 技能连载 - 性能（第 2 部分）：从 2 秒到 200 毫秒"
description: 'PowerTip of the Day - Performance (Part 2): From 2 sec to 200ms'
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们对一种常见的脚本模式提升了它的性能。现在，我们用一个更不常见的技巧进一步挤出更多性能。以下是我们上次的进展：

```powershell
$start = Get-Date

$bucket = 1..100000 | ForEach-Object {
    "I am adding $_"
}

$bucket.Count

(Get-Date) - $start
```

我们已经将执行时间从 6+ 分钟降到在 PowerShell 5.1 中 46 秒，在 PowerShell 6.1 中 1.46 秒。

现在我们看一看这个小改动——它返回完全相同的结果：

```powershell
$start = Get-Date

$bucket = 1..100000 | & { process {
    "I am adding $_"
} }

$bucket.Count

(Get-Date) - $start
```

这段神奇的代码在 PowerShell 5.1 中只花了 0.2 秒，在 PowerShell 6.1 中只花了 0.5 秒。

如您所见，这段代码只是将 `ForEach-Object` cmdlet 替换为等价的 `$ { process { $_ }}`。结果发现，由于 cmdlet 绑定的高级函数，管道操作符的执行效率被严重地拖慢了。如果使用一个简单的函数（或是一个纯脚本块），就可以显著地加速执行速度。结合昨天的技能，我们已经设法将处理从 6+ 分钟提速到 200 毫秒，而得到完全相同的结果。

请注意一件事情：这些优化技术只适用于大量迭代的循环。如果您的循环只迭代几百次，那么感受不到显著的区别。然而，一个循环迭代越多次，错误的设计就会导致越严重的消耗。


<!--本文国际来源：[Performance (Part 2): From 2 sec to 200ms](http://community.idera.com/powershell/powertips/b/tips/posts/performance-part-2-from-2-sec-to-200ms)-->
