---
layout: post
date: 2024-03-05 00:00:00
title: "PowerShell 技能连载 - PowerShell函数的手把手指南"
description: "A step-by-step guide for function in Powershell"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
为了在多个脚本中重复使用相同的代码，我们使用PowerShell函数。

PowerShell函数是一组已经被命名的PowerShell语句。每当我们想要运行一个函数时，我们需要输入它的名称。

函数可以像cmdlet一样具有参数。可以通过管道或命令行访问函数参数。
它们返回一个值，该值可以赋给变量或作为命令行参数或函数参数传递。为了指定返回值，我们可以使用关键字return

# 函数语法

以下是用于Function的语法。

```powershell
function [<scope:>]<name> [([type]$parameter1[,[type]$parameter2])]
{
  param([type]$parameter1 [,[type]$parameter2])
  dynamicparam {<statement list>}
  begin {<statement list>}
  process {<statement list>}
  end {<statement list>}
}
```

以上语法中包括以下术语：

1. 一个函数关键短语
2. 您选择的名称
3. 功能范围（可选）
4. 可以有任意数量的命名参数。
5. 一个或多个 PowerShell 命令被大括号括起来。

函数示例：

```powershell
function Operation{
   $num1 = 8
   $num2 = 2
   Write-Host "Multiply : $($num1*$num2)"
   Write-Host "Addition : $($num1+$num2)"
   Write-Host "Subtraction : $($num1-$num2)"
   Write-Host "Divide : $($num1 / $num2)"
}
Operation
```

结果：

```
Multiply : 16
Addition : 10
Subtraction : 6
Divide : 4
```

# 函数范围

* 在 PowerShell 中，函数存在于创建它的范围内。
* 如果一个函数包含在脚本中，那么它只能在该脚本中的语句中使用。
* 当我们在全局范围指定一个函数时，我们可以在其他函数、脚本和命令中使用它。

# PowerShell 中的高级功能

高级功能是可以执行类似于 cmdlet 执行的操作的功能。当用户想要编写一个不必编写已编译 cmdlet 的函数时，他们可以使用这些功能。

使用已编译 cmdlet 和高级功能之间主要区别是已编译 cmdlet 是.NET Framework 类，必须用.NET Framework 语言编写。此外，高级功能是用 PowerShell 脚本语言编写的。

以下示例展示了如何使用 PowerShell 的高级功能：

```powershell
function show-Message
{
    [CmdletBinding()]
    Param (
    [ Parameter (Mandatory = $true)]

        [string] $Name
    )
    Process
    {
        Write-Host ("Hi $Name !")
        write-host $Name "today is $(Get-Date)"
    }
}

show-message
```

结果：

```text
cmdlet show-Message at command pipeline position 1
Supply values for the following parameters:
Name: Dhrub
Hi Dhrub !
Dhrub today is 09/01/2021 13:41:12
```

# 结论

我们在每种语言中都使用函数，通常会减少代码的行数。如果您的代码有1000行，那么借助函数的帮助，您可以将计数降至500。希望您喜欢这篇文章，我们下一篇文章再见。

<!--本文国际来源：[8 Best Powershell scripts to manage DNS](https://powershellguru.com/dns-powershell-scripts/)-->
