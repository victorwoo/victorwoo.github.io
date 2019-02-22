---
layout: post
date: 2016-09-28 00:00:00
title: "PowerShell 技能连载 - Enum 之周: 理解枚举值"
description: 'PowerTip of the Day - Enum Week: Understanding Enumeration Values'
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
这周我们将关注枚举类型：它们是什么，以及如何利用它们。

在前一个技能中，我们探讨了枚举是如何工作的。您可能还记得我们如何改变控制台的前景色：

```shell
PS> $host.UI.RawUI.ForegroundColor = 'Red'

PS> $host.UI.RawUI.ForegroundColor = 'White'

PS>
```

这些代码先将前景色改为红色，然后改回白色。用字符串表达的颜色名称隐式地转换为对应的 `System.ConsoleColor enumeration` 值。

多数枚举只是数字值的一种简易的标签。"`Red`" 和 "`White`" 实际上是 integer 数值：

```shell
PS> [int][System.ConsoleColor]'Red'
12

PS> [int][System.ConsoleColor]'White'
15
```

所以如果您知道数字值，您也可以使用它们：

```shell
PS> $host.UI.RawUI.ForegroundColor = 12

PS> $host.UI.RawUI.ForegroundColor = 15
```

当然，很明显地，代码变得很难读懂。不过，还是有一种使用场合。如果您想随机设置您的控制台颜色，您可以使用数值型的值。一共有 16 种控制台颜色，所以这段代码能够用一个随机的背景色和前景色重新为您的控制台着色：

```powershell
$background, $foreground = 0..15 | Get-Random -Count 2 
$host.UI.RawUI.BackgroundColor = $background 
$host.UI.RawUI.ForegroundColor = $foreground
```

<!--本文国际来源：[Enum Week: Understanding Enumeration Values](http://community.idera.com/powershell/powertips/b/tips/posts/enum-week-understanding-enumeration-values)-->
