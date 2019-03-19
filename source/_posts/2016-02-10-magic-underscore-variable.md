---
layout: post
date: 2016-02-10 12:00:00
title: "PowerShell 技能连载 - 神奇的下划线变量"
description: PowerTip of the Day - Magic Underscore Variable
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
以下是一个非常特别（并且有详细文档的）的使用 PowerShell 变量的方法。请看这个函数：

```powershell
#requires -Version 2

function Test-DollarUnderscore
{
  param
  (
    [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [string]
    $Test
  )

  process
  {
    "received: $Test"
  }
}
```

它初看起来并没有什么特别之处。您可以将数值赋给 `-Test` 参数，并且该函数返回它们：

```powershell
PS C:\> Test-DollarUnderscore -Test 'Some Data'
received: Some Data
```

但是请看当您通过管道传送一个数据给该函数时发生了什么：

```shell
PS C:\> 1..4 | Test-DollarUnderscore -Test { "I am receiving $_" }
received: I am receiving 1
received: I am receiving 2
received: I am receiving 3
received: I am receiving 4
```

`-Test` 参数瞬间自动神奇地接受脚本块了（虽然赋予的类型是 string）。而且在脚本块中，您可以存取输入管道的数据。

您能得到这个非常特别的参数支持功能是因为您为一个必选参数设置了 `ValueFromPipelineByPropertyName=$true`，并且输入的数据没有一个属性和该参数匹配。

<!--本文国际来源：[Magic Underscore Variable](http://community.idera.com/powershell/powertips/b/tips/posts/magic-underscore-variable)-->
