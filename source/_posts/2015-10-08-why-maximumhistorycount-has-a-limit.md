---
layout: post
date: 2015-10-08 11:00:00
title: "PowerShell 技能连载 - 为什么 $MaximumHistoryCount 容量有限"
description: PowerTip of the Day - Why $MaximumHistoryCount has a Limit
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您想增加最大命令历史的容量，您可能会遇到这样的限制：

    PS C:\> $MaximumHistoryCount  = 100000

    The variable cannot be  validated because the value 100000 is not a valid value for the Maximum
    HistoryCount variable.

这里并没有提示合法的范围是多少。有意思的地方是这个变量的合法范围保存在哪。答案是：您可以查询这个变量的 `ValidateRange` 属性：

    $variable = Get-Variable MaximumHistoryCount
    $variable.Attributes
    $variable.Attributes.MinRange
    $variable.Attributes.MaxRange

但您遇到一个变量在原始数据类型之外有数值限制，您可能需要检查变量的属性来确认其中是否有验证器属性。

<!--本文国际来源：[Why $MaximumHistoryCount has a Limit](http://community.idera.com/powershell/powertips/b/tips/posts/why-maximumhistorycount-has-a-limit)-->
