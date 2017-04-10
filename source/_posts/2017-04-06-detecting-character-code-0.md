layout: post
date: 2017-04-06 00:00:00
title: "PowerShell 技能连载 - 检测字符代码 0"
description: PowerTip of the Day - Detecting Character Code 0
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
有些时候，字符串适用 "`\0`" 作为分隔符。不像其它大多数分隔符，这个分隔符并不显示在文本输出中，但仍然可以用于分割文本。

PowerShell 可以处理包含字符代码 0 的字符串。它用反斜杠后跟着数字 0 来表示。请注意文本需要放在双引号之内，才能将反斜杠序列转换为字节 0。

以下是一个演示如何分割 `\0` 分割的文本的例子：

```powershell
# create a sample text
$text = "Part 1`0Part 2`0Part 3"
# delimiter does not show in output...
$text 
# ...but can be used to split:
$text -split "`0"
```

<!--more-->
本文国际来源：[Detecting Character Code 0](http://community.idera.com/powershell/powertips/b/tips/posts/detecting-character-code-0)
