layout: post
date: 2015-10-09 11:00:00
title: "PowerShell 技能连载 - 为变量增加 ValidateRange"
description: PowerTip of the Day - Adding ValidateRange to a Variable
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
如果您希望为一个变量增加一个合法数值的范围，您可以向该变量添加一个 ValidateRange 属性，很像函数参数的工作方式。唯一的区别在，它手工作用于您期望的变量上：

    $test = 1
    $variable = Get-Variable test
    $validateRange = New-Object -TypeName System.Management.Automation.ValidateRangeAttribute(1,100)
    $variable.Attributes.Add($validateRange)
    $test = 10
    $test = 100
    $test = 1000

变量 `$test` 现在只允许 1 到 100 的数值。当您试图赋一个该范围之外的值时，会得到一个异常。

    PS C:\> $test =  101
    The variable cannot be  validated because the value 101 is not a valid value for the test
    variable.
    At line:1 char:1
    + $test = 101
    + ~~~~~~~~~~~
        +  CategoryInfo          : MetadataError:  (:) [], ValidationMetadataException
        +  FullyQualifiedErrorId : ValidateSetFailure

<!--more-->
本文国际来源：[Adding ValidateRange to a Variable](http://community.idera.com/powershell/powertips/b/tips/posts/adding-validaterange-to-a-variable)
