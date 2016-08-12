layout: post
title: "PowerShell 技能连载 - PowerShell函数的详细输出"
date: 2013-09-19 00:00:00
description: PowerTip of the Day - Verbose Output for PowerShell Functions
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
若要为您的PowerShell函数增加指定的详细输出信息（verbose output），请增加 `CmdletBinding` 属性到您的函数，使它支持公共参数。
（译者注：公共参数例如 `-Verbose`、`-Debug` 等）

	function test
	{
	    [CmdletBinding()]
	    param()
	} 

下一步，添加 `Write-Verbose` 来输出文本信息。它们仅当用户指定了 `-Verbose` 参数时才有效：

	function test
	{
	    [CmdletBinding()]
	    param()
	
	    Write-Verbose "Starting"
	    "Doing Something"
	    Write-Verbose "Shutting Down"
	} 

所以当您按以下方式运行它时，您会见到正常的输出信息：

	PS > test

	Doing Something

然而，如果您增加了 `-Verbose` 参数，您将会看到您输出的详细信息：

	PS > test -Verbose

	Starting
	Doing Something
	Shutting Down

<!--more-->

本文国际来源：[Verbose Output for PowerShell Functions](http://powershell.com/cs/blogs/tips/archive/2013/09/19/verbose-output-for-powershell-functions.aspx)
