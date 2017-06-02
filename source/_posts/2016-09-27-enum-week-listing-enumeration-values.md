---
layout: post
date: 2016-09-27 00:00:00
title: "PowerShell 技能连载 - Enum 之周: 列出枚举值"
description: 'PowerTip of the Day - Enum Week: Listing Enumeration Values'
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

在前一个技能中我们解释了 PowerShell 如何将字符串转换为枚举值。如果您想知道某个枚举参数可以用接受哪些字符串，请先看一个简单的改变控制台颜色的例子：

```powershell
PS> $host.UI.RawUI.ForegroundColor = 'Red'

PS> $host.UI.RawUI.ForegroundColor = 'White'

PS>  
```

这些命令先将前景色改为红色，然后改回白色。


但是您怎么知道控制台支持的颜色名称呢？首先您需要知道 `ForegroundColor` 的真实数据类型：

```powershell
PS> $host.UI.RawUI.ForegroundColor.GetType().FullName 
System.ConsoleColor
```

它的类型是 "`System.ConsoleColor`"。现在您可以检查它是否确实是一个枚举型：

```powershell
PS> $host.UI.RawUI.ForegroundColor.GetType().IsEnum
True
```

如果它确实是，例如这个例子，您可以列出它所有的值的名称：

```powershell
PS> [System.Enum]::GetNames([System.ConsoleColor])
Black
DarkBlue
DarkGreen
DarkCyan
DarkRed
DarkMagenta
DarkYellow
Gray
DarkGray
Blue
Green
Cyan
Red
Magenta
Yellow
White
```

这些值中的每一个值都可以用来设置控制台的前景色。这种方法可以应用在所有接受枚举值的属性或参数上。

同样地，如果您传入了一个和所有枚举值名称都不相同的值，异常信息中也会列出枚举值的名字。

<!--more-->
本文国际来源：[Enum Week: Listing Enumeration Values](http://community.idera.com/powershell/powertips/b/tips/posts/enum-week-listing-enumeration-values)
