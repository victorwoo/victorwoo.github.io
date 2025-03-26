---
layout: post
date: 2023-08-20 00:00:00
title: "PowerShell 技能连载 - 理解PowerShell中的错误处理"
description: "Understanding Error handling in Powershell"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在编写代码时，错误管理是必须的。预期行为经常可以进行检查和验证。当发生意外情况时，我们使用异常处理。您可以轻松处理其他人代码抛出的异常，或者创建自己的异常供他人处理。

## PowerShell 中的异常是什么？

异常是一种事件类型，在标准错误处理无法解决问题时会被触发。尝试将一个数字除以零或耗尽内存都属于异常情况。当特定问题出现时，您正在使用其代码的创建者可能会创建异常。

## PowerShell 中的 Throw、Try 和 Catch

当发生异常时，我们称之为抛出了一个异常。您必须捕获抛出的异常才能对其进行管理。如果未通过任何方式捕获引发了一个未被捕获的异常，则脚本将停止运行。

同样地，我们有 Try 可以放置任何逻辑并使用 try 来捕获该异常。以下分别是 throw、try 和 catch 的一些示例。

我们使用 throw 关键字来生成自己的例外事件。

```powershell
function hi
function hi
{
 throw "hi all"
}
```

这会抛出一个运行时异常，这是一个致命错误。调用函数中的**catch**语句处理它，或者脚本以类似这样的通知离开。

```plaintext
hi

hi all
At line:3 char:1
+ throw "hi all"
+ ~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (hi all:String) [], RuntimeException
    + FullyQualifiedErrorId : hi all
```

在PowerShell（以及许多其他语言中），异常处理的工作方式是首先尝试一部分代码，然后在它抛出错误时捕获它。这里有一个示例来说明我的意思。

```powershell
function hi
{
throw "hi all"

 }
 try hi
{

catch
{
    Write-Output "Something threw an exception"
}

##Output:

Something threw an exception
```

## PowerShell 中的 finally 块

在 PowerShell 中的最终块

您并不总是需要处理错误，但无论是否发生异常，都需要一些代码来运行。这正是 finally 块所做的。finally 中的代码最终会被执行。

```powershell
function hi
{
throw "hi all"

 }

 try
{
    hi
}

catch
{
    Write-Output "Something threw an exception"
}

Finally

{
"PowershellGuru"
}

## Output ##

Something threw an exception
PowershellGuru
```

## Cmdlet -ErrorAction

当您在任何高级函数或 cmdlet 中使用 [\-ErrorAction](https://devblogs.microsoft.com/powershell/erroraction-and-errorvariable/) Stop 选项时，它会将所有 Write-Error 语句转换为终止错误，从而停止执行或可以被捕获。

类似地，我们有 -ErrorAction SilentlyContinue 选项，如果出现错误，则不显示错误并继续执行而不中断。

让我向您展示如何在脚本中使用这些。

```powershell
$ErrorActionPreference = "Stop"

script-start
'
'
'
script-end
```

我们可以使用“SilentlyContinue”来代替“Stop”。这样做的好处是我们不必在每一行都提到它所需的地方。

## 结论

在本文中，我们已经介绍了异常、try/catch/throw/finally以及示例。此外，我们还看到了-ErrorAction cmdlets 以及如何实际使用它们。现在应该知道Powershell中异常处理的重要性了。让我们在下一篇文章中见面。

<!--本文国际来源：[Understanding Error handling in Powershell](https://powershellguru.com/error-handling-in-powershell/)-->
