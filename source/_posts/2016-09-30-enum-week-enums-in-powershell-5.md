---
layout: post
date: 2016-09-30 00:00:00
title: "PowerShell 技能连载 - Enum 之周: PowerShell 5 中的枚举"
description: 'PowerTip of the Day - Enum Week: Enums in PowerShell 5'
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
*支持 PowerShell 5 以上版本*

这周我们将关注枚举类型：它们是什么，以及如何利用它们。

从 PowerShell 5 开始，您可以用 "`Enum`"创建您自己的枚举类型。通过这种方式，用户可以用可阅读的名字，而不是幻数。

```powershell
#requires -Version  5.0

Enum ComputerType
{
  ManagedServer
  ManagedClient
  Server
  Client
}

function Connect-Computer
{
  param
  (
    [ComputerType]
    $Type,

    [string]
    $Name
  )

  "Computername: $Name Type: $Type"
}
```

当您运行完这段代码，并调用 "`Connect-Computer`" 函数之后，PowerShell 自动为您的枚举值提供智能提示，并且只接受枚举类型里规定的值。

```shell
PS C:\> Connect-Computer -Type Client -Name Test
Computername: Test Type: Client

PS C:\>
```

<!--本文国际来源：[Enum Week: Enums in PowerShell 5](http://community.idera.com/powershell/powertips/b/tips/posts/enum-week-enums-in-powershell-5)-->
