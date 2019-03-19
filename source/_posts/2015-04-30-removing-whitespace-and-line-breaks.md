---
layout: post
date: 2015-04-30 11:00:00
title: "PowerShell 技能连载 - 移除空白（和换行）"
description: PowerTip of the Day - Removing Whitespace (and Line Breaks)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
您也许知道每个 string 对象都有个 `Trim()` 方法可以删除该字符串开头和结尾的空白：

    $text = '    Hello     '
    $text.Trim()

一个鲜为人知的事实是，`Trim()` 也会删掉开头和结尾的换行：

    $text = '

     Hello


     '
    $text.Trim()

如果您需要，您可以控制 `Trim()` 函数吃掉的字符。

这个例子删除空格、点号、减号和换行：

    $text = '

     ... Hello

     ...---
     '
    $text.Trim(" .-`t`n`r")

<!--本文国际来源：[Removing Whitespace (and Line Breaks)](http://community.idera.com/powershell/powertips/b/tips/posts/removing-whitespace-and-line-breaks)-->
