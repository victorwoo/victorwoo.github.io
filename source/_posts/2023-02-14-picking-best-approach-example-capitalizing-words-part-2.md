---
layout: post
date: 2023-02-14 00:00:40
title: "PowerShell 技能连载 - 选择最佳方法：单词转大写（第 2 部分）"
description: 'PowerTip of the Day - Picking Best Approach: Example Capitalizing Words (Part 2)'
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

在 PowerShell 中要解决一个问题最简单的方法是使用合适的 PowerShell cmdlet。可以使用 `Get-Command` 来搜索已有的 cmdlet。在第一部分中我们已经发现没有一个特定的 PowerShell cmdlet 可以做这件事，所以不得不使用低级的方法来解决这个任务。

由于我们现在已经有解决方案，我们只需要将以下代码转为一个全新的 PowerShell cmdlet（这样我们不需要重复发明这个解决方案，以及我们的生产代码变得更精炼切易于理解和回顾）：

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

将一段代码转为一个可重用的 cmdlet 只需要按照这些固定的步骤：将代码封装在一个函数中，然后定义它的输入（被称为参数）。例如这样：

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
        # split text in words
        $words = $Text -split '\s{1,}' |
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
    }
}
```

请注意头部和尾部的代码。函数中实现逻辑的部分（这个例子中的文本转换部分）仍然保持不变。

当您运行以上代码，PowerShell 设置您的新函数。然后您可以按自己的喜好任意多次调用它，并且由于它是支持管道的，所以您甚至可以通过管道将文本从其它 cmdlet 传给它。如果您想，您可以使用 `Get-Content` 来读取整个文本并使用 `Convert-CapitalizeWord` 将每个单词的首字母改为大写——PowerShell 中的函数像一个奇迹，能够使得函数可复用以及可伸缩：

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

您可以将函数复制/粘贴到需要使用的脚本中。

为了让函数认识并自动加载（类似所有其它“内置”PowerShell cmdlet），并且成为您 shell 的一个永久的命令扩展，您可以将函数存储在模块中。

目前，收获是：通过包装代码在函数，使得代码可重用，自动添加了可扩展性（在上面的例子中，我们现在可以转换在一个调用中转换一个或者上千个字符串），以及使生产脚本代码变得更短，可以专注于它真正想要完成什么。
<!--本文国际来源：[Picking Best Approach: Example Capitalizing Words (Part 2)](https://blog.idera.com/database-tools/powershell/powertips/picking-best-approach-example-capitalizing-words-part-2/)-->

