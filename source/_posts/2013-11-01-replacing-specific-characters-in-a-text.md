---
layout: post
title: "PowerShell 技能连载 - 替换文本中的指定字符"
date: 2013-11-01 00:00:00
description: PowerTip of the Day - Replacing Specific Characters in a Text
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您只是需要替换文本中字符出现的所有位置，这是很简单的。以下可以将文本中所有的“l”变为大写：

	"Hello World".Replace('l', 'L')

然而有些时候，您需要替换特定位置的某几个字符。我们假设您的文本是一个比特掩码，并且您需要对某些比特置位或清除。以上代码是不能用的，因为它一口气改变了所有的位：

	PS> "110100011110110".Replace('1', '0')
	
	000000000000000

而且您也不能通过索引来改变字符。您可以读取一个字符（例如检查某一个位是否为“1”），但您无法改变它的值：

	PS> "110100011110110"[-1] -eq '1'
	False

	PS> "110100011110110"[-2] -eq '1'
	True
	
	PS> "110100011110110"[-2] = '0'
	无法对 System.String 类型的对象进行索引。

要改变一个字符串中的某些字符，请将它转换为一个 `StringBuilder`：

	PS> $sb = New-Object System.Text.StringBuilder("1101100011110110")
	
	PS> $sb[-1]
	0
	
	PS> $sb[-1] -eq '1'
	False
	
	PS> $sb[-2] -eq '1'
	True
	
	PS> $sb[-2] = '0'
	
	PS> $sb[-2] -eq '1'
	False
	
	PS> $sb.ToString()
	110100011110100

以下是将二进制转换为十进制格式的方法：

	PS> $sb.ToString()
	110100011110100
	
	PS> [System.Convert]::ToInt64($sb.ToString(), 2)
	26868

<!--本文国际来源：[Replacing Specific Characters in a Text](http://community.idera.com/powershell/powertips/b/tips/posts/replacing-specific-characters-in-a-text)-->
