layout: post
date: 2015-02-24 12:00:00
title: "PowerShell 技能连载 - 将文件的扩展名正常化"
description: PowerTip of the Day - Normalizing File Extensions
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
_适用于 PowerShell 2.0 及以上版本_

假设您希望用户提交一个文件扩展名的列表，或者是从某些其它来源获取这个列表。

文件扩展名是模糊标准的绝好例子。您要如何指定一个文本文件的扩展名呢？是用 ".txt" 还是 "*.txt"？

以下是一个将文件的扩展名正常化的简单技巧，无论它们如何拼写都有效：

    $extensions = '*.ps1', '.txt'
    $cleanExtensions = $extensions -replace '^\.', '*.'
    
    $extensions
    $cleanExtensions

<!--more-->
本文国际来源：[Normalizing File Extensions](http://community.idera.com/powershell/powertips/b/tips/posts/normalizing-file-extensions)
