layout: post
title: "PowerShell 技能连载 - 多个返回值"
date: 2013-09-09 00:00:00
description: PowerTip of the Day - Returning Multiple Values
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
一个PowerShell函数可以有多个返回值。要接收这些返回值，只需要将返回值赋给多个变量：

	function Get-DateTimeInfo
	{
	    # Value 1
	    Get-Date -Format 'dddd'
	
	    # Value 2
	    Get-Date -Format 'MMMM'
	
	    # Value 3
	    Get-Date -Format 'HH:mm:ss'
	}
	
	$day, $month, $time = Get-DateTimeInfo
	
	"Today is $day, the month is $month, and it is $time" 

<!--more-->

本文国际来源：[Returning Multiple Values](http://powershell.com/cs/blogs/tips/archive/2013/09/09/returning-multiple-values.aspx)
