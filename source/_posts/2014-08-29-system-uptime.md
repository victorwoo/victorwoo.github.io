---
layout: post
date: 2014-08-29 11:00:00
title: "PowerShell 技能连载 - 获取系统开机时长"
description: PowerTip of the Day - System Uptime
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell 所有版本_

Windows 每次启动的时候，都启动一个高精度计数器，这个计数器将返回系统运行的毫秒数：

    $millisecondsUptime = [Environment]::TickCount
    "I am up for $millisecondsUptime milliseconds!"

由于您很难对毫秒有兴趣，所以请使用 `New-TimeSpan` 来将毫秒（顺便提一下，也可以是任何其它时间间隔）转换为有意义的单位：

    $millisecondsUptime = [Environment]::TickCount
    "I am up for $millisecondsUptime milliseconds!"

    $timespan = New-TimeSpan -Seconds ($millisecondsUptime/1000)
    $timespan

那么现在，您可以使用 TimeSpan 型的 `$timespan` 对象以您想要的任何格式来汇报启动的时间：

    $millisecondsUptime = [Environment]::TickCount
    "I am up for $millisecondsUptime milliseconds!"

    $timespan = New-TimeSpan -Seconds ($millisecondsUptime/1000)
    $hours = $timespan.TotalHours

    "System is up for {0:n0} hours now." -f $hours

由于 `New-TimeSpan` 无法直接处理毫秒，所以需要做一个特殊处理。该脚本直接将毫秒数除以 1000，会引入一个小误差。

要将毫秒数转换为一个 `TimeSpan` 对象而不损失任何精度，请试试以下代码：

    $timespan = [Timespan]::FromMilliseconds($millisecondsUptime)

在这个例子中，它们没有区别。但是它在其它情况下可能很有用。例如，您还可以使用 `FromTicks()` 方法将时钟周期数（Windows 系统中的最小时间周期单位）转换为时间间隔。

<!--本文国际来源：[System Uptime](http://community.idera.com/powershell/powertips/b/tips/posts/system-uptime)-->
