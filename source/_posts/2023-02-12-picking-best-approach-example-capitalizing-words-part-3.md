---
layout: post
date: 2023-02-12 16:40:39
title: "PowerShell 技能连载 - 选择最佳方法：单词转大写（第 3 部分）"
description: 'PowerTip of the Day - Picking Best Approach: Example Capitalizing Words (Part 3)'
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

在前一部分中，我们已经使用 PowerShell 操作符和通用的字符串方法来解决问题。然而，在代码中通常有一个真理：使用越专用的命令，代码就越简洁。

所以 PowerShell 可以使用另一个来源的命令：从和 PowerShell 一起分发的上千个 .NET 库中选择静态 .NET 方法。有一个比通用操作符和字符串方法简单得多的解决方案：

```powershell
$text = "thIS is    A  TEST teXT"
[CultureInfo]::InvariantCulture.TextInfo.ToTitleCase($text)
Words that are ALL CAPITALIZED will remain untouched:


This Is    A  TEST Text
```

如果您不喜欢有些例外的单词没有被转成首字母大写，那么先将文本转为全小写然后传给该方法：

```powershell
PS> [CultureInfo]::InvariantCulture.TextInfo.ToTitleCase('TEST remains aLL uppER Case')
TEST Remains All Upper Case

PS> [CultureInfo]::InvariantCulture.TextInfo.ToTitleCase('TEST remains aLL uppER Case unless you lowerCASE YOUR text beFORE'.ToLower())
Test Remains All Upper Case Unless You Lowercase Your Text Before
```

如您所见（和这个系列之前的部分相比），空格仍然保持不变，由于我们从没有将文本分割为独立的单词。如果您不喜欢这一点，并且想将多个空格符合并为一个，只需要添加 `-replace` 运算符。它能将所有字符串整理好：

```powershell
$text = "thIS is    A  TEST teXT"
# title convert and then replace two or more spaces with one space only:
[CultureInfo]::InvariantCulture.TextInfo.ToTitleCase($text.ToLower()) -replace '\s{2,}', ' '
Now this approach returns the exact same result as in our previous parts:


This Is A Test Text
```

以上代码很短并且很简单，这样您可以直接在代码合适的地方使用它，但是您下星期或者下个月要做相同的转换时还能记得它吗？

所以仍然可以将该代码包装成为一个函数。您可以将我们在第 2 部分中创建的函数升级为更新更有效的方式：

```powershell
function Convert-CapitalizeWord
{
    param
    (
        [Parameter(Mandatory,ValueFromPipeline)]
        $Text
    )

    process
    {
        [CultureInfo]::InvariantCulture.TextInfo.ToTitleCase($text.ToLower()) -replace '\s{2,}', ' '
    }
}
```

当您运行该函数，它将和之前的版本一样灵活和可扩展：

```powershell
# you get automatic prompts when you forget to submit mandatory arguments:
PS> Convert-CapitalizeWord
cmdlet Convert-CapitalizeWord at command pipeline position 1
Supply values for the following parameters:
Text: heLLO WOrld
Hello World

# you can submit your text to the -Text parameter:
PS> Convert-CapitalizeWord -Text 'this iS a LONG teXT'
This Is A Long Text

# you can pipe as many texts as you like (scalable) via the pipeline:
PS> 'Hello world!', 'someTHING else' | Convert-CapitalizeWord
Hello World!
Something Else
```
<!--本文国际来源：[Picking Best Approach: Example Capitalizing Words (Part 3)](https://blog.idera.com/database-tools/powershell/powertips/picking-best-approach-example-capitalizing-words-part-3/)-->

