layout: post
title: "PowerShell 技能连载 - 轻松地格式化数字"
date: 2014-03-05 00:00:00
description: PowerTip of the Day - Formatting Numbers Easily
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
用户常常需要格式化数字并且限制小数的位数，或者是在左侧补零。有一个简单标准的方法：使用操作符 `-f` ！

以下代码的作用是左侧补零：

    $number = 68
    '{0:d7}' -f $number 

这段代码将生成一个左补零的 7 位数字。调整“d”后的数字可以控制位数。

要限制小数的位数，请使用“n”来代替“d”。这一次，“n”后的数字控制小数的位数：

    $number = 35553568.67826738
    '{0:n1}' -f $number 

类似地，用“p”来格式化百分比：

    $number = 0.32562176536
    '{0:p2}' -f $number 

<!--more-->
本文国际来源：[Formatting Numbers Easily](http://community.idera.com/powershell/powertips/b/tips/posts/formatting-numbers-easily)
