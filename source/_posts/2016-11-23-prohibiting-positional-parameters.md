layout: post
date: 2016-11-23 00:00:00
title: "PowerShell 技能连载 - 禁止按位置的参数"
description: PowerTip of the Day - Prohibiting Positional Parameters
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
当您创建 PowerShell 函数时，参数可以是命名的也可以是按位置的。以下是一个例子：

如果您想检测文件系统中的非法字符，以下是一个简单的适配：

```powershell
function Test-Command
{
  param
  (
    [string]$Name,
    [int]$Id
  )

  "Name: $Name ID: $ID"
}

Test-Command -Name Weltner -Id 12
Test-Command Weltner 12
```

如您所见，使用按位置的参数（只需要指定参数，不需要显式地指定参数名）可能更适用于为特定目的编写的代码，但是可读性更差。这是有可能的，因为上述函数的语法看起来如下：

```powershell
  Test-Command [[-Name] <string>] [[-Id] <int>]
```

那么一个编写一个效果相反的 PowerShell 函数，实现这种语法呢：

```powershell
Test-Command [-Name <string>] [-Id <int>] [<CommonParameters>]
```

目前这个方法比较生僻，不过是完全可行的：

```powershell
function Test-Command
{
  param
  (
    [Parameter(ParameterSetName='xy')]
    [string]$Name,

    [Parameter(ParameterSetName='xy')]
    [int]$Id
  )

  "Name: $Name ID: $ID"
}
```

一旦开始使用参数集合，缺省情况下所有参数都是命名的参数。
<!--more-->
本文国际来源：[Prohibiting Positional Parameters](http://community.idera.com/powershell/powertips/b/tips/posts/prohibiting-positional-parameters)
