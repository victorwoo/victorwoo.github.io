---
layout: post
title: "PowerShell 技能连载 - PowerShell 4.0 中的动态方法"
date: 2013-11-05 00:00:00
description: PowerTip of the Day - Dynamic Methods in PowerShell 4
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
从 PowerShell 4.0 开始，方法名可以是一个变量。以下是一个简单的例子：

	$method = 'ToUpper'
	'Hello'.$method() 

当您需要调用的方法须通过一段脚本计算得到的时候，这个特性十分有用。

	function Convert-Text
	{
	  param
	  (
	    [Parameter(Mandatory)]
	    $Text,
	    [Switch]$ToUpper
	  )
	
	  if ($ToUpper)
	  {
	    $method = 'ToUpper'
	  }
	  else
	  {
	    $method = 'ToLower'
	  }
	  $text.$method()
	} 

以下是用户调用该函数的方法：

	PS> Convert-Text 'Hello'
	hello
	PS> Convert-Text 'Hello' -ToUpper
	HELLO

缺省情况下，该函数将文本转换为小写。当指定了开关参数 `-ToUpper` 时，函数将文本转换为大写。由于动态方法特性的支持，该函数不需要为此写两遍代码。

译者注：在旧版本的 PowerShell 中，您可以通过 .NET 方法（而不是脚本方法）中的反射来实现相同的目的。虽然它不那么整洁，但它能运行在 PowerShell 4.0 以下的环境：

	function Convert-Text
	{
	  param
	  (
	    [Parameter(Mandatory)]
	    $Text,
	    [Switch]$ToUpper
	  )
	
	  if ($ToUpper)
	  {
	    $method = 'ToUpper'
	  }
	  else
	  {
	    $method = 'ToLower'
	  }
	  $methodInfo = $Text.GetType().GetMethod($method, [type[]]@())
	  $methodInfo.Invoke($Text, $null)
	} 

<!--more-->
本文国际来源：[Dynamic Methods in PowerShell 4](http://community.idera.com/powershell/powertips/b/tips/posts/dynamic-methods-in-powershell-4)
