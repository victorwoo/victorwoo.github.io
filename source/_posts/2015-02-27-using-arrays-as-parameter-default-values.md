---
layout: post
date: 2015-02-27 12:00:00
title: "PowerShell 技能连载 - 使用数组作为参数的缺省值"
description: PowerTip of the Day - Using Arrays as Parameter Default Values
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
_适用于 PowerShell 3.0 及以上版本_

如果您定义的 PowerShell 函数有几个参数，并且希望某个参数的缺省值是一个数组，您可能会遇到语法问题：

    function Get-SomeData
    {
      param
      (
        $ServerID = 1,2,5,10,11
      )
    
      "Your choice: $ServerID"
    }

PowerShell 使用逗号来分隔参数，所以在 `param()` 块中的 "1" 之后的逗号会被曲解，PowerShell 会认为这是一个接下来定义的新参数。

当会发生歧义的时候，使用圆括号来确保这些部分是一个整体。以下是一段完美合法的代码：

    function Get-SomeData
    {
      param
      (
        $ServerID = (1,2,5,10,11)
      )
    
      "Your choice: $ServerID"
    }

<!--more-->
本文国际来源：[Using Arrays as Parameter Default Values](http://community.idera.com/powershell/powertips/b/tips/posts/using-arrays-as-parameter-default-values)
