---
layout: post
date: 2014-09-29 11:00:00
title: "PowerShell 技能连载 - 分隔文本"
description: PowerTip of the Day - Text Splitting
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell 所有版本_

我们可以用 `-split` 操作符按指定的分隔符来分隔文本。这个操作符接受一个正则表达式作为操作数，所以如果您只是希望用纯文本的表达式来作为分隔的操作数，那么您需要将该纯文本转义一下。

以下是用反斜杠来分隔路径的例子：

    $originalText = 'c:\windows\test\file.txt'
    $splitText = [RegEx]::Escape('\')

    $originalText -split $splitText

结果类似如下，并且它是一个数组：

    PS> $originalText -split $splitText
    c:
    windows
    test
    file.txt

我们可以将它保存到一个变量中，然后存取单个的数组元素。

    PS> $parts = $originalText -split $splitText

    PS> $parts[0]
    c:

    PS> $parts[-1]
    file.txt

<!--本文国际来源：[Text Splitting](http://community.idera.com/powershell/powertips/b/tips/posts/text-splitting)-->
