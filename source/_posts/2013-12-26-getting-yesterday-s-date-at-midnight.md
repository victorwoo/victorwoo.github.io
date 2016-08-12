layout: post
title: "PowerShell 技能连载 - 获取昨天午夜的日期值"
date: 2013-12-26 00:00:00
description: "PowerTip of the Day - Getting Yesterday’s Date - at Midnight!"
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
当您了解了每个 `DateTime` 对象支持 `Add...()` 方法之后，获取相对日期（例如昨天或下周）就十分容易了。以下代码可以获取昨天的时间值：

	$today = Get-Date
	$yesterday = $today.AddDays(-1)
	$yesterday

`$yesterday` 的值是当前时间之前 24 小时整的值。那么如果您希望得到昨天特定时刻的值，比如说昨天午夜呢？

如果您希望得到今天午夜的值，那么十分简单：

	$todayMidnight = Get-Date -Hour 0 -Minute 0 -Second 0
	$todayMidnight

如果您希望得到另一天的该时间值，那么再次使用 Get-Date 来修改时间值。以代码获取昨天午夜的时间值：

	$today = Get-Date
	$yesterday = $today.AddDays(-1)
	$yesterday | Get-Date -Hour 0 -Minute 0 -Second 0

> 译者注：如果您只是需要获取昨天午夜的日期值，还可以有其它方法。如：`(Get-Date).AddDays(-1).Date` 或 `[System.DateTime]::Today.Subtract([System.TimeSpan]::FromDays(1))`。

<!--more-->
本文国际来源：[Getting Yesterday’s Date - at Midnight!](http://powershell.com/cs/blogs/tips/archive/2013/12/26/getting-yesterday-s-date-at-midnight.aspx)
