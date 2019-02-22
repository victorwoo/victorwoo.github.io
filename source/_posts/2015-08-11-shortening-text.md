---
layout: post
date: 2015-08-11 11:00:00
title: "PowerShell 技能连载 - 截短文本"
description: PowerTip of the Day - Shortening Text
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
假设您希望截掉一个字符串尾部的一些文字。以下是使用字符串操作的传统方法：

    $text = "Some text"
    $fromRight = 3
    
    $text.Substring(0, $text.Length - $fromRight)

一个更强大的方法是使用 `-replace` 操作符结合正则表达式：

    $text = "Some text"
    $fromRight = 3
    
    $text -replace ".{$fromRight}$"

这段代码将去掉文字尾部（`$`）之前 `$fromRight` 个任意字符（"`.`"）。

由于正则表达式十分灵活，所以您可以重新编辑它，只截去数字，且最多只截掉 5 个数字：

    $text1 = "Some text with digits267686783"
    $text2 = "Some text with digits3"
    
    $text1 -replace "\d{0,5}$"
    $text2 -replace "\d{0,5}$"

量词“`{0,5}`”告诉正则表达式引擎需要 0 到 5 个数字，引擎会尽可能多地选取。

<!--本文国际来源：[Shortening Text](http://community.idera.com/powershell/powertips/b/tips/posts/shortening-text)-->
