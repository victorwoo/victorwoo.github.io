---
layout: post
date: 2019-05-18 00:00:00
title: "PowerShell 技能连载 - 以固定宽度分割文本"
description: PowerTip of the Day - Splitting Texts by Fixed Width
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
假设您需要以固定狂赌分割一段文本。例如，如果您需要一段文本的前 5 个字符，以及剩余的部分，如何实现它？

大多数 PowerShell 用户可能会用类似这样的方法：

```powershell
$text = 'ID12:Here is the text'$prefix = $text.Substring(0,5)$suffix = $text.Substring(5)$prefix$suffix
```

当然，如果用分割字符，例如 ":"，可以这样操作：

```powershell
$prefix, $suffix = 'ID12:Here is the text' -split ':'$prefix$suffix
```

然而，这将会吃掉分割字符，并且它会导致超过两个部分。这不是我们要的目标：用固定宽度分割一段文本。而您仍然可以使用 `-split` 操作符：

```powershell
$prefix, $suffix = 'ID12:Here is the text' -split '(?<=^.{5})'$prefix$suffix
```

正则表达式结构 "`(?<=XXX)`" 称为“向后引用”。"`^`" 代表文本的开始，而 "`.`" 代表任何字符。如您猜测的那样，"`{5}`" 限定该占位符出现的次数，所以基本上这个正则表达式从剩下的文本中分割出前 5 个字符并且返回两部分（假设文本至少 6 个以上字符长度）。

<!--本文国际来源：[Get Hashes from Texts](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/splitting-texts-by-fixed-width)-->

