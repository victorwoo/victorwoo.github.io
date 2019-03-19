---
layout: post
title: "用 PowerShell 处理纯文本 - 3"
date: 2013-11-01 00:00:00
description: Processing Plain Text with PowerShell - 3
categories:
- powershell
- text
tags:
- powershell
- learning
- skill
- script
---
命题：
> 怎样把字符 "ABC-EFGH-XYZ" 替换为 "012-3456-789"

为了解决这个 case，先归纳它的规律：

* 注意字符集和数字之间的对应关系，我们可以自定义一个字符集来表示。
* 保留 - 号。
* 不区分大小写，提高适应性。

根据以上规律编写 PowerShell 代码：

	$charSet = 'ABCEFGHXYZ'.ToCharArray()

	$text = 'ABC-EFGH-XYZ'

	$array = ($text.ToUpper().ToCharArray() | % {
		if ($_ -eq '-') {
		    '-'
		} else {
		    [string]([System.Array]::IndexOf($charSet, $_))
		}
	})

	$array -join ''

结果是：

	012-3456-789
