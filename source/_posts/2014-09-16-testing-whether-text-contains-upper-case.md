---
layout: post
date: 2014-09-16 11:00:00
title: "PowerShell 技能连载 - 检测文本中是否含有大写字母"
description: PowerTip of the Day - Testing Whether Text Contains Upper Case
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell 任何版本_

可以使用正则表达式来检测一个字符串是否包含至少一个大写字母：

    $text1 = 'this is all lower-case'
    $text2 = 'this is NOT all lower-case'
    
    $text1 -cmatch '[A-Z]'
    $text2 -cmatch '[A-Z]' 

得到的结果分别是“`Frue`”和“`False`”。

要检测一段文本是否只包含小写字母，请试试这段代码：

    $text1 = 'this is all lower-case'
    $text2 = 'this is NOT all lower-case'
    
    $text1 -cmatch '^[a-z\s-]*$'
    $text2 -cmatch '^[A-Z\s-]*$' 

得到的结果分别是“`True`”和“`False`”。

实际上检测起来会更麻烦，因为您需要包括所有合法的字符。在这个例子中，我选择了 a-z 的小写字母、空格和减号。

这些“合法”的字符被包含在“`^`”和“`$`”（行首符和行尾符）之间。星号是一个量词（任意数量个“合法的”字符）。

<!--本文国际来源：[Testing Whether Text Contains Upper Case](http://community.idera.com/powershell/powertips/b/tips/posts/testing-whether-text-contains-upper-case)-->
