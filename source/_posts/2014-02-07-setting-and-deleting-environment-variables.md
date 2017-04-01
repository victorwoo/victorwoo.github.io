layout: post
title: "PowerShell 技能连载 - 设置（及删除）环境变量"
date: 2014-02-07 00:00:00
description: PowerTip of the Day - Setting (And Deleting) Environment Variables
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
PowerShell 可以很容易地读取环境变量。以下代码返回当前的 Windows 文件夹：

	$env:windir

然而，如果您想永久地改变用户或机器的环境变量，您需要使用 .NET 的功能。以下是一个可以快速设置或删除环境变量的简单函数：

	function Set-EnvironmentVariable
	{
	    param
	    (
	        [Parameter(Mandatory=$true, HelpMessage='Help note')]
	        $Name,
	
	        [System.EnvironmentVariableTarget]
	        $Target,
	
	        $Value = $null
	
	    )
	
	    [System.Environment]::SetEnvironmentVariable($Name, $Value, $Target )
	}


要创建一个永久的环境变量，试试以下代码：

	PS> Set-EnvironmentVariable -Name TestVar -Value 123 -Target User

请注意新的用户变量只对新运行的应用程序可见。已运行的应用程序将会保持它们的运行环境副本，除非它们显式地请求改变后的变量。

以下是删除该环境变量的代码：

	PS> Set-EnvironmentVariable -Name TestVar -Value '' -Target User

<!--more-->
本文国际来源：[Setting (And Deleting) Environment Variables](http://community.idera.com/powershell/powertips/b/tips/posts/setting-and-deleting-environment-variables)
