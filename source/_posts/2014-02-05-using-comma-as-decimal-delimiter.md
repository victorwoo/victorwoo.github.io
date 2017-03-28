layout: post
title: "PowerShell 技能连载 - 用逗号作为十进制数分隔符"
date: 2014-02-05 00:00:00
description: PowerTip of the Day - Using Comma as Decimal Delimiter
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
也许您还没有意识到，PowerShell 在输入输出时用的是不同的十进制分隔符——这也许会导致脚本用户产生混淆。

当您输入信息时，PowerShell 接受的是语言中性的格式（使用“.”作为十进制分隔符）。当输出信息时，它使用的是您的区域设置（所以在许多国家，使用的是“,”）。

请实践一下看看以下是否和您的文化相符：

	$a = 1.5
	$a
	1,5

这是一个良好的设计，因为使用语言中性的输入格式，脚本执行情况永远相同，无论区域设置如何。然而，如果您希望用户能使用逗号作为分隔符，请看以下脚本：

	function Multiply-LocalNumber
	{
	      param
	      (
	            [Parameter(Mandatory=$true)]
	            $Number1,
	
	            $Number2 = 10
	      )
	
	      [Double]$Number1 = ($Number1 -join '.')
	      [Double]$Number2 = ($Number2 -join '.')
	
	      $Number1 * $Number2
	}

用户可以任选一种方式运行：

	PS> Multiply-LocalNumber 1.5 9.223
	13,8345
	
	PS> Multiply-LocalNumber 1,5 9,223
	13,8345

当用户选择使用逗号，PowerShell 实际上将它解释成一个数组。这是为什么脚本将数组用“.”连接的原因，实际上是将数组转换为一个数字。`-join` 的执行结果是一个字符串，该字符串需要被转换成一个数字，所以一切正常。

当然，这是个有点黑客的技巧，它总比每次首先得指导您的用户必须使用“.”分隔符来得好。

<!--more-->
本文国际来源：[Using Comma as Decimal Delimiter](http://community.idera.com/powershell/powertips/b/tips/posts/using-comma-as-decimal-delimiter)
