layout: post
date: 2016-11-22 00:00:00
title: "PowerShell 技能连载 - 在 PowerShell 函数中使用命名的函数"
description: PowerTip of the Day - Using Named Parameters in PowerShell Functions
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
当您创建一个 PowerShell 函数时，所有参数都有默认的位置，除非人为地加上“`Position`”属性。一旦加上这个属性，所有不带“`Position`”的参数将立刻变为命名的必须参数。让我们看看例子：

这是一个经典的函数定义，创建了三个固定位置的参数：

```powershell
function Test-Command
{
  param
  (
    [string]$Name,
    [int]$ID,
    [string]$Email
  )

  # TODO: Code using the parameter values
}
```

语法如下：

```
Test-Command [[-Name] <string>] [[-ID] <int>] [[-Email] <string>]
```

一旦您在任何一个参数上添加“`Position`”属性，其它的就变为命名的参数：

```powershell
function Test-Command
{
  param
  (
    [Parameter(Position=0)]
    [string]$Name,
    [Parameter(Position=1)]
    [int]$ID,
    [string]$Email
  )

  # TODO: Code using the parameter values
}
```

以下是它的语法：

```
Test-Command [[-Name] <string>] [[-ID] <int>] [-Email <string>] [<CommonParameters>]
```

区别在哪？您不需要指定参数名 `-Name` 和 `-ID`，但如果您希望为第三个参数指定一个值，必须指定 `-Email`。在第一个例子中，所有三个参数都可以按照位置来定位。

<!--more-->
本文国际来源：[Using Named Parameters in PowerShell Functions](http://community.idera.com/powershell/powertips/b/tips/posts/using-named-parameters-in-powershell-functions)
