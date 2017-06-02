---
layout: post
title: "PowerShell 技能连载 - 创建日历（和日期列表）"
date: 2013-10-10 00:00:00
description: PowerTip of the Day - Creating Calendars (and Lists of Dates)
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
以下是一段创建 `DateTime` 集合的脚本片段。只需要指定年和月，脚本将会针对该月的每一天创建一个 `DateTime` 对象：

	$month = 8
	$year = 2013
	
	1..[DateTime]::DaysInMonth($year,$month) |
	  ForEach-Object { Get-Date -Day $_ -Month $month -Year $year }

这段代码十分有用：只要加一个日期过滤器，您就可以过滤出工作日来。它将列出指定月份的所有周一至周五（因为它排除了 weekday 0（星期日）和 weekday 6（星期六））：

	$month = 8
	$year = 2013
	
	1..[DateTime]::DaysInMonth($year,$month) |
	  ForEach-Object { Get-Date -Day $_ -Month $month -Year $year } |
	  Where-Object { 0,6 -notcontains $_.DayOfWeek }
	
类似地，以下代码将统计指定月份所有星期三和星期五的天数：

	$month = 8
	$year = 2013
	
	$days = 1..[DateTime]::DaysInMonth($year,$month) |
	  ForEach-Object { Get-Date -Day $_ -Month $month -Year $year } |
	  Where-Object { 3,5 -contains $_.DayOfWeek }
	
	$days
	"There are {0} Wednesdays and Fridays" -f $days.Count

<!--more-->

本文国际来源：[Creating Calendars (and Lists of Dates)](http://community.idera.com/powershell/powertips/b/tips/posts/creating-calendars-and-lists-of-dates)
