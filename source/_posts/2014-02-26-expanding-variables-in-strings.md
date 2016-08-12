layout: post
title: "PowerShell 技能连载 - 展开字符串中的变量"
date: 2014-02-26 00:00:00
description: PowerTip of the Day - Expanding Variables in Strings
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
要在一个字符串中插入一个变量，您也许已经知道可以使用如下的双引号方式：

    $domain = $env:USERDOMAIN
    $username = $env:USERNAME
    
    "$domain\$username"

对于 PowerShell 来说这些变量的起止范围是没有歧义的。所以它可以工作正常。然而试试以下代码：

    $domain = $env:USERDOMAIN
    $username = $env:USERNAME
    
    "$username: located in domain $domain"

这段代码执行失败了，这是因为 PowerShell 在变量中添加了冒号（从语法彩色中也可以看出）。

您可以采用 PowerShell 的反引号来为特殊字符（比如说冒号）转义：

    $domain = $env:USERDOMAIN
    $username = $env:USERNAME
    
    "$username`: located in domain $domain"
    
如果问题不是由于特殊字符引起的，那么这种方法没有作用：

    "Current Background Color: $host.UI.RawUI.BackgroundColor" 
    
语法高亮提示双引号引起来的字符串中只解析出了变量，而其它部分（变量名之后的部分，比如说对象的属性）并没有解析出来。

要解决这个问题，您需要使用以下的方法之一：

    "Current Background Color: $($host.UI.RawUI.BackgroundColor)"
    'Current Background Color: ' + $host.UI.RawUI.BackgroundColor
    'Current Background Color: {0}' -f $host.UI.RawUI.BackgroundColor


<!--more-->
本文国际来源：[Expanding Variables in Strings](http://powershell.com/cs/blogs/tips/archive/2014/02/26/expanding-variables-in-strings.aspx)
