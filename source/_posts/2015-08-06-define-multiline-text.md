---
layout: post
date: 2015-08-06 11:00:00
title: "PowerShell 技能连载 - 定义多行文本"
description: PowerTip of the Day - Define Multiline Text
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
当您需要在 PowerShell 中定义多行文本时，通常可以这样使用 here-string：

    $text = @"
      I am safe here
      I can even use "quotes"
    "@
    
    $text | Out-GridView

值得注意的重点是分隔符包含（不可见的）回车符。必须在开始标记后有一个，在结束标记前有一个。

一个很特殊的另一种用法是使用脚本块来代替：

    $text = {
      I am safe here
      I can even use "quotes"
    }
    
    $text.ToString() | Out-GridView

虽然代码颜色不同，并且需要将脚本块转为字符串。这种方法有一定局限性，因为脚本块是一段 PowerShell 代码，并且它会被解析器解析。所以您只能包裹一段不会造成解析器混淆的文本。

这个是个不合法的例子，将会造成语法错误，因为非闭合的双引号：

    $text = {
      I am safe here
      I can even use "quotes
    }
    
    $text.ToString() | Out-GridView

<!--more-->
本文国际来源：[Define Multiline Text](http://community.idera.com/powershell/powertips/b/tips/posts/define-multiline-text)
