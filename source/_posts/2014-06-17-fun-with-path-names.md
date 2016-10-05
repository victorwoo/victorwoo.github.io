layout: post
title: "PowerShell 技能连载 - 有趣的路径名"
date: 2014-06-17 00:00:00
description: PowerTip of the Day - Fun with Path Names
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
您可以用 `-split` 运算符轻松地将一个路径分割成独立的部分。结果是一个数组。

只需要用比较运算符来排除您不需要的部分，或者对其中的一部分改名，然后用 `-join` 运算符将路径合并回来。

以下代码将排除掉某个路径下所有包含单词“test”的子文件夹：

    $path = 'C:\folder\test\unit1\testing\results\report.txt'
    
    $path -split '\\' -notlike '*test*' -join '\'

<!--more-->
本文国际来源：[Fun with Path Names](http://community.idera.com/powershell/powertips/b/tips/posts/fun-with-path-names)
