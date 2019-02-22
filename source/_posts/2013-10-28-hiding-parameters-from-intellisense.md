---
layout: post
title: "PowerShell 技能连载 - 在智能感知中隐藏参数"
date: 2013-10-28 00:00:00
description: PowerTip of the Day - Hiding Parameters from IntelliSense
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
从 PowerShell 4.0 开始，脚本作者可以决定隐藏某些参数，使之不在智能感知中出现。通过这种方式，可以在 ISE 的智能感知上下文菜单中隐藏不常用的参数。

	function Test-Function
	{
	    param(
	        $Name,
	        [Parameter(DontShow)]
	        [Switch]
	        $IAmSecret
	    )
	    
	    if ($IAmSecret)
	    {
	     "Doing secret things with $Name"
	    }
	    else
	    {
	      "Regular behavior with $Name"
	    }
	}

当您在 PowerShell 4.0 ISE 中运行这个函数时，只有 "Name" 参数会出现在智能感知上下文菜单中。然而，如果您事先知道这个隐藏参数，并且键入了第一个字母，然后按下 (TAB) 键，这个参数仍会显示：
![](/img/2013-10-29-hiding-parameters-from-intellisense-001.png)

在帮助窗口，隐藏参数总是可以显示，您可以通过类似这种方式打开：
![](/img/2013-10-29-hiding-parameters-from-intellisense-002.png)

<!--本文国际来源：[Hiding Parameters from IntelliSense](http://community.idera.com/powershell/powertips/b/tips/posts/hiding-parameters-from-intellisense)-->
