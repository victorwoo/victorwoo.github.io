layout: post
title: "PowerShell 技能连载 - 确保向后兼容"
date: 2014-02-12 00:00:00
description: PowerTip of the Day - Ensuring Backward Compatibility
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
假设您创建了这个函数：

	function Test-Function
	{
	  param
	  (
	    [Parameter(Mandatory=$true)]
	    $ServerPath
	  )
	
	  "You selected $ServerPath"
	}


它现在可以正常工作，但是在半年之后的代码审查中，您的老板希望您使用标准的参数名称，将“ServerPath”改名为“ComputerName”。那么您对您的代码做出适当的修改：

	function Test-Function
	{
	  param
	  (
	    [Parameter(Mandatory=$true)]
	    $ComputerName
	  )
	
	  "You selected $ComputerName"
	}

然而，您不能很容易地控制哪些人调用了您的函数，而且他们使用了旧的参数。所以要确保向后兼容，请确保您的函数使用旧的参数名也可以工作：

	function Test-Function
	{
	  param
	  (
	    [Parameter(Mandatory=$true)]
	    [Alias("ServerPath")]
	    $ComputerName
	  )
	
	  "You selected $ComputerName"
	}

旧的代码任然可以运行，并且新的代码（以及代码自动完成）将会使用新的名称：

![](/img/2014-02-12-ensuring-backward-compatibility-001.png)

<!--more-->
本文国际来源：[Ensuring Backward Compatibility](http://community.idera.com/powershell/powertips/b/tips/posts/ensuring-backward-compatibility)
