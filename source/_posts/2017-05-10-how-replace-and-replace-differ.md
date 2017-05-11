layout: post
date: 2017-05-10 00:00:00
title: "PowerShell 技能连载 - .Replace() 和 -replace 的区别"
description: PowerTip of the Day - How .Replace() and -replace differ
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
有两种方法可以替换一个字符串中的问本：`Replace()` 方法，和 `-replace` 操作符。它们的工作机制是不同的。

`Replace()` 是大小写敏感的，能够将文本替换为新的文本：

```powershell
PS> 'Hello World.'.Replace('o', '0')
Hell0 W0rld

PS> 'Hello World.'.Replace('ell','oo')
Hooo World
```

`-replace` 操作符缺省是大小写不敏感的（如果希望大小写敏感，请使用 `-creplace`）。它接受一个正则表达式输入，很多人忽略了这个功能：

```powershell
PS> 'Hello World.' -replace 'ell', 'oo'
Hooo World.

PS> 'Hello World.' -replace '.', '!'
!!!!!!!!!!!!
```

第二个输出会让不了解正则表达式的人感到惊讶。如果您希望用 `-replace` 来替换静态文本，请确保对文本进行转义：

```powershell
PS> 'Hello World.' -replace [Regex]::Escape('.'), '!'
Hello World!
```

<!--more-->
本文国际来源：[How .Replace() and -replace differ](http://community.idera.com/powershell/powertips/b/tips/posts/how-replace-and-replace-differ)
