---
layout: post
date: 2014-09-30 11:00:00
title: "PowerShell 技能连载 - 高级文本分隔"
description: PowerTip of the Day - Advanced Text Splitting
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
_适用于 PowerShell 所有版本_

当您用 `-split` 操作符来分隔文本时，分隔符本身会被忽略掉：

    PS> 'Hello, this is a text, and it has commas' -split ','
    Hello
     this is a text
     and it has commas

如您所见，结果中的逗号被忽略掉了。

分隔符有可能多于一个字符。以下代码将以逗号 + 一个空格作为分隔符：

    PS> 'Hello, this is a text, and it has commas' -split ', '
    Hello
    this is a text
    and it has commas 

由于 `-split` 接受的操作数是一个正则表达式，所以以下代码将以逗号 + 至少一个空格作为分隔符：

    PS> 'Hello,    this is a    text, and it has commas' -split ',\s{1,}'
    Hello
    this is a    text
    and it has commas 

如果您需要的话，可以用 `(?=…)` 把分隔符包裹起来，以在结果中保留分隔符：

    PS> 'Hello,    this is a    text, and it has commas' -split '(?=,\s{1,})'
    Hello
    ,    this is a    text
    , and it has commas

<!--more-->
本文国际来源：[Advanced Text Splitting](http://community.idera.com/powershell/powertips/b/tips/posts/advanced-text-splitting)
