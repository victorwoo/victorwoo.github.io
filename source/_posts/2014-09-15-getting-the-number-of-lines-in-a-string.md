layout: post
date: 2014-09-15 11:00:00
title: "PowerShell 技能连载 - 获取字符串的行数"
description: 'PowerTip of the Day - Getting the Number of Lines in a String '
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

Here is a clever trick how to find out how many lines a string (not a string array!) contains:
以下是一个获取字符串（而不是字符串数组！）行数的技巧：

    $text = @'
    This is some
    sample text
    Let's find out
    the number of lines.
    '@
    
    $text.Length - $text.Replace("`n",'').Length + 1 

技术上来说，这个例子用的是 here-string 来创建多行字符串，不过这只是一个例子。它对所有类型的字符串都有效，无论它的来源是什么。

<!--more-->
本文国际来源：[Getting the Number of Lines in a String ](http://community.idera.com/powershell/powertips/b/tips/posts/getting-the-number-of-lines-in-a-string)
