---
title: 准备一场 PowerShell 技术面试
description: Preparing for a PowerShell Interview
date: 2017-06-03 13:39:25
tags: [powershell]
categories: [powershell]
---
## 理解 Windows PowerShell 是什么

初学者的第一个问题总是“请告诉我，PowerShell 是什么？”

PowerShell 不仅仅是一个新的 shell（外壳）。**PowerShell 是一个面向对象的分布式自动化引擎、脚本语言，以及命令行 shell。**我不指望一个初学者能完全理解我刚才说的，不过至少，我希望您能理解 PowerShell 天生是面向对象的。如果说“~~因为 PowerShell 是基于 .NET 框架的，所以它是面向对象的~~”，这句话并不太准确。实际上，我们说 PowerShell 是面向对象的，是因为它处理的是对象而不是文本。让我们看一个例子。

这是我在 DOS 的批处理脚本中获取一个文件夹（包括子文件夹等）大小的方法：

    @echo off
    For /F "tokens=*" %%a IN ('"dir /s /-c /a | find "bytes" | find /v "free""') do Set xsummary=%%a
    For /f "tokens=1,2 delims=)" %%a in ("%xsummary%") do set xfiles=%%a&set xsize=%%b
    Set xsize=%xsize:bytes=%
    Set xsize=%xsize: =%
    Echo Size is: %xsize% Bytes

您看到这有多痛苦了吗？有多少人能理解这段批处理脚本到底在做什么？

好吧，让我们来看看用 PowerShell 如何实现。

    Get-ChildItem –Recurse | Measure-Object -Property Length -Sum

很简单吧？至少，它看上去很清爽。这是因为 PowerShell 能处理对象——那些能自我描述的东西。这些对象拥有各种属性。文件对象有一个 `Length` 属性是代表文件的大小有多少字节的。所以，我们把文件夹下所有文件的大小加起来，就能得到文件夹的大小。如何你把这段 PowerShell 脚本和刚才的 DOS 批处理脚本做一个比较，可以看出我们用不着处理任何临时变量和解析文本。我们只需要将 `Get-ChildItem` cmdlet 的结果通过管道输出到 `Measure-Object`，并且将管道中传过来的每个对象的 `Length` 属性求和即可。

好了，这是一个解释 PowerShell 天生是面向对象的一个小例子。当您开始学习 PowerShell 之后，将可以举出更多类似的例子。

我们再假设一个问题“**如何获得某个进程的 CPU 相关性？**”，您会怎么实现？

有些人会这么做：

    $process = Get-Process -Name notepad

目前这么操作 OK。然后他们接下来在键盘上敲：

`$process.<Tab> <Tab> <Tab> … <Tab>` 直到找到所需要的属性为止。

虽然这么做也没错，可以获得您要的属性，不过万一你要的属性是 100 个属性中的第 99 个呢？显然不太明智，是吧？现在学习 shell 的使用就很有帮助了。在 shell 中有更好的办法实现这个。

如果您知道精确的属性名：

    Get-Process -Name Notepad | Select-Object ProcessorAffinity

或者

    $process = Get-Process -Name Notepad
    $process.ProcessorAffinity

如果您不知道精确的属性名，不要一直按 `Tab`！请用 PowerShell 的自我探索功能。这是接下来我们要讨论的问题。

## 学习如何探索 PowerShell

初学者最重要的事情是了解如何使用以下的 cmdlet：

* Get-Command
* Get-Member
* Get-Help

### Get-Command

`Get-Command` 返回一个 PowerShell 会话中可用的所有命令。据我观察，某些初学者在输入一个不存在的或者错误的 cmdlet 名字以后，一直在纠结为什么不能用。如果我们知道如何探索 PowerShell，我们就可以用 `Get-Command` cmdlet 来验证我们想要用的命令是否存在。例如：

    PS C:\> Get-Command -Name Get-ComputerName
    Get-Command : The term 'Get-ComputerName' is not recognized as the name of a cmdlet, function, script file, or operable program. Check
    the spelling of the name, or if a path was included, verify that the path is correct and try again.
    At line:1 char:1
    + Get-Command -Name Get-ComputerName
    + ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo : ObjectNotFound: (Get-ComputerName:String) [Get-Command], CommandNotFoundException
    + FullyQualifiedErrorId : CommandNotFoundException,Microsoft.PowerShell.Commands.GetCommandCommand

见到了吗？您还可以用 `Get-Command` 针对特定的动词或者名词来获取命令，甚至可以使用通配符来过滤。

    Get-Command -Noun Host
    Get-Command -Verb Write
    Get-Command N*

### Get-Member

在前面的段落中，我们学习了如何获得一个对象的某个属性。但是，只有您精确地知道属性名才能用。那么我们如何探索某个对象中有哪些属性和方法可用呢？`Get-Member` 这时候派上用场了。

    Get-Process | Get-Member

以上命令可以获取某个对象类型的所有属性、方法和事件。您可以对它进一步地筛选来找到您感兴趣的成员。

Get-Process | Get-Member -MemberType Method
Get-Process | Get-Member -MemberType Property
Get-Process | Get-Member -MemberType Event

### Get-Help

另外一个初学者常见的问题是对内置的帮助系统没什么概念。PowerShell 内置的 cmdlet 都带有如何使用的详细说明。当然，在 PowerShell 3.0 及更高的版本，您首先需要用 `Update-Help` cmdlet 来更新帮助内容。当您想了解某个 PowerShell cmdlet 的详细语法时，您就可以使用用 `Get-Help` cmdlet。它能告诉您 cmdlet 参数的信息、如何使用每个参数、以及提供一些例子。当不明白怎么使用时，您第一件事就应该是查看本地的帮助系统。

    Get-Help Get-Command
    Get-Help Get-Member -Detailed
    Get-Help Get-Process –Examples
    Get-Help Get-Service –Parameter InputObject

## 使用 shell

我不指望一个初学者能掌握编写脚本和模块的知识。但至少要掌握使用 shell 的技能。您必须亲自动手实践一下内置的 cmdlet。这包括了一些简单的操作，比如说列出服务、进程、文件和文件夹。至少要会用 `Get-ChildItem` 来递归地搜索文件，才算是接触到了 PowerShell 的表层，才算是一名初学者。

在学习 PowerShell 的过程中，您应该从 shell 开始学起。基本上在 PowerShell 命令行中能运行的一切命令，都能在脚本中运行。所以一开始可以在 shell 中用 PowerShell 语言和内置的 cmdlet 来做一些简单的任务。最终，您将会学习如何编写脚本。这是初学 PowerShell 很重要的一个方向。

某些人对我说，他们只了解一些特定产品专用的 PowerShell cmdlet，并且他们只要用哪些 cmdlet 就够了。那么能告诉我只用特定产品专用的 cmdlet 而不用任何内置的 cmdlet、管道以及 PowerShell 语言要怎么完成一个自动化任务呢？这是不可能做到的。如果有些人认为可能，那么很可能他们根本不了解基础只是或者从来没有用过 shell。

### 学习管道

在用 PowerShell 的过程中，如果要有效地使用它，您需要了解什么是管道，以及您可以将多个命令用管道连接起来。我在前面段落的例子中已经用到了管道，只是没有深入讲解它是什么。运行一个简单的命令不是什么难事。不过当您把多个命令用管道连接起来变成一个更大的任务时，您就会意识到管道的强大之处。要完整地讨论管道的知识，需要 50 - 75 页书才能讲完。让我们保持这篇文章简单易懂一些。

我们假想 PowerShell 的管道是一个制造单元的一条组装线。在一个制造单元中，部件从一个站点传递到另一个站点以及输出端，一路装配过来。我们可以在组装线的最末端看到装配完成的产品。通过类似这样的方式，当我们将多个 PowerShell cmdlet 用管道连接起来时，一个命令的输出结果会作为下一个命令的输入参数。例如：

    Get-Process -Name s* | Where-Object { $_.HandleCount -lt 100 }


在上述命令中，`Get-Process` 命令输出的一个或多个对象会作为输入送给 `Where-Object` cmdlet。`Where-Object` 命令过滤出输入对象数组中 `HandleCount` 属性小于 100 的对象。您当然也可以不用管道来完成这个任务。让我们看看做起来是怎么样。

    $process = Get-Process -name s*
    foreach ($proc in $process) {
       if ($proc.HandleCount -lt 100) {
           $proc
       }
    }

如您所见，要写更多的代码。这还不是大问题，您会看到生成输出时的区别。在这个例子里，许多人认为第一个命令执行完以后，所有的输出结果送入第二个命令。这样描述并不精确。在管道中，第一个命令每生成一个对象，就立即向第二个命令传递。

前一个例子只合并了两个命令，所以看起来很微不足道。让我们看看下一个例子：

    Get-ChildItem -Recurse -Force |
    Where-Object {$_.Length -gt 10MB} |
    Sort-Object -Property Length -Descending |
    Select-Object Name, @{name='Size (MB)'; expression={$_.Length/1MB}}, Extension |
    Group-Object -Property extension

我不指望一名初学者能理解这段代码，或是写出这样的代码。不过，这段代码显示出管道的强大之处。上述的命令（或者说用管道连接的命令）获取所有大于 10MB 的文件，将它们按文件的大小降序排列，然后将它们按文件的扩展名分组。您敢不敢不用管道将这段代码的功能实现一遍？

## 不要过度设计

PowerShell 往往提供多种方法来实现同一件事情。当然，这些方法各有差别。有效率上的差别，有简单和复杂的差别。

所以，当我提出“**请告诉我计算机名**”的需求时，我不希望您开始写一段 WMI 查询语句：

    Get-WmiObject -Class Win32_ComputerSystem | Select-Object -Property Name

或

    Get-WmiObject -Class Win32_OperatingSystem | Select-Object -Property CSName

您可能坚称这些命令确实可以获取本地计算机名。但是，请您理解有更好的方法来实现：

    $env:ComputerName

噢，用传统的 `hostname` 命令也得到了相同的结果。一切正确。我常常使用它。不过，我们现在关注的是 PowerShell，对吧？

## 编写脚本

这是另一个常见的问题。您也许知道如何运行别人写的脚本。不过，这样能使您成为一个脚本编写者吗？不可能。阅读别人写的脚本确实能帮您理解最佳和最差实践。但是，当您是一个初学者时，这不会有助于您的学习。只有您自己动手编写自己的脚本才能学到知识。

还有，不要轻易说您会编写高级的函数。除非您知道如何描述通用参数、参数类型、`cmdletbinding`，以及 `Begin`、`Process` 和 `End` 代码块是如何工作和为什么需要它们。如果您不了解这些概念，就不要觉得自己写过 PowerShell 的高级函数。高级函数和我们平时在 PowerShell 中写的普通函数是不同的。当您在函数定义中增加了 `CmdletBinding()` 以后，函数的基本行为就改变了。我们来看一个例子吧？

以下是一个普通函数，接受两个数字输入参数，并且返回它们的和。

    function sum {
        param (
           $number1,
           $number2
        )
        $number1 + $number2
    }
     
    PS C:\> sum 10 30
    40

现在，用不同个数的参数来调用这个函数。

    PS C:\> sum 10 30 40
    40

见到了吗？虽然我们在函数定义中只有两个参数，但它也可以接受三个参数，并且只是把第三个参数忽略掉。现在，加入 `CmdletBinding()` 属性并看看行为发生什么变化。

    function sum {
       [CmdletBinding()]
       param (
          $number1,
          $number2
       )
       $number1 + $number2
    }

用先前一样的参数再次测试！

    PS C:\> sum 10 30
    40
     
    PS C:\> sum 10 30 40
    sum : A positional parameter cannot be found that accepts argument '40'.
    At line:1 char:1
    + sum 10 30 40
    + ~~~~~~~~~~~~
    + CategoryInfo : InvalidArgument: (:) [sum], ParameterBindingException
    + FullyQualifiedErrorId : PositionalParameterNotFound,sum

见到了吗？加入了 `CmdletBionding()` 属性以后，处理输入参数的基本行为发生了变化。这是一个高级的 PowerShell 函数。但是，这只是开头。我们在这里不再深入下去，我希望您在告诉我写过高级函数之前知道这些。

## 不要依赖搜索引擎

我听很多人说他们写脚本的时候要依赖 Google。他们只是使用搜索引擎，查找问题现成的解决方案，并且直接拿来用。他们常常是开始编写脚本或者尝试做一个任务几分钟就放弃了。我只有在我彻底没有思路，实在继续不下去的时候才用搜索引擎。或者当我知道某些人已经开发了一个脚本并且我不想重复发明轮子的时候。但是，当我想学习 PowerShell 的时候，我不会用这种方式。搜索引擎是寻找解决方案的最简单方法，但是您从中学不到任何东西，除了怎么用搜索引擎。特别地，当您还是一个初学者时，直接使用现成的脚本对学习没有任何帮助。

祝您好运！
