---
layout: post
title: "PowerShell 技能连载 - 检测合法的时间"
date: 2014-02-04 00:00:00
description: PowerTip of the Day - Testing for Valid Date
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您想检测某个信息类似“是否是合法的日期”，以下是一个检测的函数：

	function Test-Date
	{
	    param
	    (
	        [Parameter(Mandatory=$true)]
	        $Date
	    )
	
	    (($Date -as [DateTime]) -ne $null)
	}

这段代码使用 `-as` 操作符尝试将输入数据转换为 `DateTime` 格式。如果转换失败，则结果为 `$null`，所以函数可以根据转换的结果返回 $true 或 $false。请注意，`-as` 操作符使用您的本地 `DateTime` 格式。

<!--本文国际来源：[Testing for Valid Date](http://community.idera.com/powershell/powertips/b/tips/posts/testing-for-valid-date)-->
