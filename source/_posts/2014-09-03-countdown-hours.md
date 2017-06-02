---
layout: post
date: 2014-09-03 04:00:00
title: "PowerShell 技能连载 - 计算倒计时小时数"
description: PowerTip of the Day - Countdown Hours
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
_适用于 PowerShell 所有版本_

当遇到生日或重要的赛事时，您可能会想到用 PowerShell 来计算事件还有多少小时到来。以下是实现方法：

    $result = New-TimeSpan -End '2014-12-25 06:45:00'
    $hours = [Int]$result.TotalHours
    'Another {0:n0} hours to go...' -f $hours 

这个例子计算距离 2014 年圣诞节还剩余的小时数。只需要替换代码中的日期，就可以得到距您期待的事件到来还有多少小时。

<!--more-->
本文国际来源：[Countdown Hours](http://community.idera.com/powershell/powertips/b/tips/posts/countdown-hours)
