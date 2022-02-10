---
layout: post
date: 2022-01-14 00:00:00
title: "PowerShell 技能连载 - 转义独立的字符"
description: PowerTip of the Day - Escaping Individual Characters
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中，我们解释了如何转义整个字符串序列。如果您只需要转义单个字符，请使用 `HexEscape()` 如：

```powershell
PS> [Uri]::HexEscape('a')
%61
```

此方法实际上是检索 ASCII 代码并将其转换为十六进制。

实际上，还可以进行相反的操作，您可以将转义的字符转换回正常字符。例如，"a" 的 ASCII 代码为 65，它的十六进制表达是 41。因此，"A" 的转义表示为 "％41"，这行代码将得到 "A"：

```powershell
PS C:\> [Uri]::HexUnescape('%41',[ref]0)
A
```

（第二个参数表示要转换转义的字符在字符串中的位置）。

有了这个，您现在可以生成一个范围内的字母：首先，生成所需字母的 ASCII 代码，并以十六进制形式手动转换它们。`-f` 运算符可以执行此转换：

```powershell
PS> $decimal = 65
PS> $hex = '{0:X}' -f $decimal
PS> $hex
41
```

以下是来自 A 到 Z 的转义字母：

```powershell
65..90 | ForEach-Object { '%{0:X}' -f $_ }
```

反转义它们的方法：

```powershell
65..90 | ForEach-Object { [Uri]::HexUnescape( ('%{0:X}' -f $_), [ref]0) }
```

不过，不要爱上这个过度的技巧。类型转换可以让您更轻松实现：

```powershell
[char[]](65..90)
```

<!--本文国际来源：[Escaping Individual Characters](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/escaping-individual-characters)-->

