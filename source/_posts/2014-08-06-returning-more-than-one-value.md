layout: post
date: 2014-08-06 11:00:00
title: "PowerShell 技能连载 - 产生多个返回值"
description: PowerTip of the Day - Returning More Than One Value
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
_适用于所有 PowerShell 版本_

如果一个 PowerShell 函数需要产生多个返回信息，最佳的实践方式是返回多个对象，然后将信息分别存储在对象的各个属性中。

以下是一个有趣的例外情况，它在某些场景中较为适用。尽管返回多个信息就可以了，并且要确保将结果赋值给多个变量：

    function Get-MultipleData 
    {
      Get-Date
      'Hello'
      1+4
    }
    
    $date, $text, $result = Get-MultipleData
    
    "The date is $date"
    "The text was $text"
    "The result is $result"

这个测试函数产生 3 段信息，然后将结果存储在 3 个不同的变量中。

<!--more-->
本文国际来源：[Returning More Than One Value](http://community.idera.com/powershell/powertips/b/tips/posts/returning-more-than-one-value)
