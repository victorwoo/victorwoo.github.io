---
layout: post
date: 2017-05-19 00:00:00
title: "PowerShell 技能连载 - 转义通配符"
description: PowerTip of the Day - Escape Wildcards
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您使用 `-like` 操作符时，它支持三种通配符："`*`" 代表所有数字和字母，"`?`" 代表任意单个字符，"`[a-z]`" 代表字符的列表。另外有一个不太为人所知的，它支持 PowerShell 的转义字符 "`\``"，可以用它来转义通配符。

所以当您需要检查一个字符串中的 "`*`" 字符，这行代码能够工作但实际上是错的：

```powershell
'*abc' -like '*abc'
```

这是错的，因为它在这种情况下也是返回 true：

```powershell
'xyzabc' -like '*abc'
```

由于您希望检查 "`*`" 字符并且不希望将它解释为一个通配符，所以需要对它进行转义：

```powershell
PS> '*abc' -like '`*abc'
True

PS> 'xyzabc' -like '`*abc'
False
```

而且如果您使用双引号，请不要忘了对转义符转义：

```powershell
# wrong:
PS> "xyzabc" -like "`*abc"
True

# correct:
PS> "xyzabc" -like "``*abc"
False

PS> "*abc" -like "``*abc"
True

PS>
```

<!--本文国际来源：[Escape Wildcards](http://community.idera.com/powershell/powertips/b/tips/posts/escape-wildcards)-->
