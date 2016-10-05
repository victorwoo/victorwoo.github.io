layout: post
date: 2016-09-26 00:00:00
title: "PowerShell 技能连载 - Enum 之周: 枚举的自动转换"
description: 'PowerTip of the Day - Enum Week: Auto-Conversion for Enums'
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
这周我们将关注枚举类型：它们是什么，以及如何利用它们。

当一个 Cmdlet 或者方法需要一个枚举值时，PowerShell 能毫无障碍地接受不完整的枚举名称。这个方法不为人知。例如这段代码将控制台的前景色改为灰色：

```powershell
PS> $host.UI.RawUI.ForegroundColor = 'Gray'
```

这段代码将前景色改为白色：

```powershell
PS> $host.UI.RawUI.ForegroundColor = 'White'
```

`ForegroundColor` 属性看上去是字符串类型的，但这并不是真相。它只能接受**某些**字符串。这个属性的类型实际上不是字符串型。它实际上是一个只接受某些字符串值的枚举型：

```powershell
PS> $host.UI.RawUI | Get-Member -Name ForegroundColor

​    
   TypeName: System.Management.Automation.Internal.Host.InternalHostRawUserInterface

Name            MemberType Definition                                    
----            ---------- ----------                                    
ForegroundColor Property   System.ConsoleColor ForegroundColor {get;set;} 
```

该属性实际上是 "`System.ConsoleColor`" 类型。当您传入一个类似 "`Gray`" 或 "`White`" 的字符串时，PowerShell 实际上在后台查询 `System.ConsoleColor` 类型可选的值，并将传入的字符串做转换。

一个不为人知的事实是：不需要严格的匹配。您可以用这种方法写：

```powershell
    PS>  $host.UI.RawUI.ForegroundColor = 'R'  

    PS>  $host.UI.RawUI.ForegroundColor = 'W'
```powershell

这段代码将把控制台的前景色改为红色，然后改回白色。PowerShell 只关心指定的值是否有歧义。如果传入了字符串 "`G`"，会发生异常，提示信息是名字冲突。对于灰色，至少要指定 "`Gra`"，因为任何比这个短的字符串都和 "`Green`" 相冲突。

为什么这很重要？您必须尽量使用完整的枚举值以提高可读性。只需要记着会自动转换。它帮助您理解为什么这类语句可以工作：

```powershell
    Get-Service | Where-Object { $_.Status -eq 'R' }
```

<!--more-->
本文国际来源：[Enum Week: Auto-Conversion for Enums](http://community.idera.com/powershell/powertips/b/tips/posts/enum-week-auto-conversion-for-enums)
