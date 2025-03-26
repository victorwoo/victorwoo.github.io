---
layout: post
date: 2023-02-10 00:00:47
title: "PowerShell 技能连载 - 选择最佳方法：单词转大写（第 1 部分）"
description: 'PowerTip of the Day - Picking Best Approach: Example Capitalizing Words (Part 1)'
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerShell 中，当您需要解决一个问题时，有四种不同来源的命令可以选择。在这个迷你系列中，我们依次查看所有方法。要解决的是同一个问题：如何将一个单词的首字母改为大写。请注意，这是我们随意选为例子的一个问题。该解决方案适用于任何想用 PowerShell 解决的问题。

在 PowerShell 中要解决一个问题最简单的方法是使用合适的 PowerShell cmdlet。可以使用 `Get-Command` 来搜索已有的 cmdlet。不幸的是，不可能对于*任何*问题都有完美的 cmdlet。在这种情况中可能找不到合适的 cmdlet。

在这种情况下，PowerShell 任然提供了许多途径来解决问题。在今天的解决方案中，我们使用 PowerShell 运算符和 .NET 方法：

```powershell
$text = "thIS is    A  TEST teXT"
# split text in words
$words = $text -split '\s{1,}' |
# use ForEach-Object to break down the problem to solving ONE instance of your problem
# regardless of how many words there are, the following script block deals with
# one word at a time:
ForEach-Object  {
    $theWord = $_
    # use .NET string methods on the object to solve your issue:
    $theWord.SubString(0,1).toUpper() + $theWord.SubString(1).ToLower()
}

# the result is a string array. Use the -join operator to turn it into ONE string:
$result = $words -join ' '
$result
```

结果看起来不错：

    This Is A Test Text
<!--本文国际来源：[Picking Best Approach: Example Capitalizing Words (Part 1)](https://blog.idera.com/database-tools/powershell/powertips/picking-best-approach-example-capitalizing-words-part-1/)-->

