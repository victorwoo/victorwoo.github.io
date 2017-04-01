layout: post
title: "PowerShell 技能连载 - 读取整个文本文件"
date: 2014-04-07 00:00:00
description: PowerTip of the Day - Reading All Text
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
您可以用 `Get-Content` 来读入整个文本文件。但是，`Get-Content` 是逐行返回文件的内容，您得到的是一个 string 数组，并且换行符被去掉了。

要一次性读取整个文本文件，从 PowerShell 3.0 开始，您可以使用 `-Raw` 参数（它还有个好处，能够大大加快读取文件的速度）。

所以通过以下代码您可以获得一个字符串数组，每个元素是一行文本：

![](/img/2014-04-07-reading-all-text-001.png)

Length 属性表示文件的行数。

以下代码一次性读取整个文本文件，返回单个字符串：

![](/img/2014-04-07-reading-all-text-002.png)

这回，Length 属性表示整个文件的字符数，并且读取文件的速度大大提高（虽然也更占内存了）。

那种方法更好？这取决于您要如何使用这些数据。

<!--more-->
本文国际来源：[Reading All Text](http://community.idera.com/powershell/powertips/b/tips/posts/reading-all-text)
