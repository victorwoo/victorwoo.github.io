layout: post
date: 2015-04-02 11:00:00
title: "PowerShell 技能连载 - 智能参数验证"
description: PowerTip of the Day - Clever Parameter Validation
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

当您用 PowerShell 创建带参数的函数时，请明确地告知 PowerShell 该参数的类型。

这是一个简单的例子，您需要输入一个星期数：

    function Get-Weekday
    {
      param
      (
        $Weekday
      )
      
      "You chose $Weekday"
    }

用户可以传入任何东西，不仅是正常的星期数：

    PS> Get-Weekday -Weekday NoWeekday
    You chose NoWeekday                                                 
     

有些时候，您可能会看到用正则表达式实现的验证器：

    function Get-Weekday
    {
      param
      (
        [ValidatePattern('Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday')]
        $Weekday
      )
      
      "You chose $Weekday"
    }

现在，用户的输入被限定在了这些模式中，如果输入的值不符合正则表达式的模式，PowerShell 将会抛出一个异常。然而，错误信息并不是很有用，并且用户输入的时候并不能享受到智能提示的便利。

一个更好的方法是使用验证集合：

    function Get-Weekday
    {
      param
      (
        [ValidateSet('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')]
        $Weekday
      )
      
      "You chose $Weekday"
    }

现在，用户只能输入您允许的值，并且用户在 PowerShell ISE 中输入的时候会获得智能提示信息，显示允许输入的值。

如果您了解您期望值对应的 .NET 的枚举类型，那么可以更简单地将该类型绑定到参数上：

    function Get-Weekday
    {
      param
      (
        [System.DayOfWeek]
        $Weekday
      )
      
      "You chose $Weekday"
    }

<!--more-->
本文国际来源：[Clever Parameter Validation](http://powershell.com/cs/blogs/tips/archive/2015/04/02/clever-parameter-validation.aspx)
