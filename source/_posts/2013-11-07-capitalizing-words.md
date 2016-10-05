layout: post
title: "PowerShell 技能连载 - 将单词首字母转换为大写"
date: 2013-11-07 00:00:00
description: PowerTip of the Day - Capitalizing Words
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
要正确地将单词首字母转换为大写，您可以用正则表达式或者一点系统函数：

用正则表达式的话，您可以这样做：

	$sentence = 'here is some text where i would like the first letter to be capitalized.'
	$pattern = '\b(\w)'
	[RegEx]::Replace($sentence, $pattern, { param($x) $x.Value.ToUpper() }) 

用系统函数的话，这样做可以达到相同的效果：

	$sentence = 'here is some text where i would like the first letter to be capitalized.'
	(Get-Culture).TextInfo.ToTitleCase($sentence) 

正则表达式稍微复杂一点，但是功能更多。例如如果出于某种古怪的原因，您需要将每个单词的首字母替换为它的 ASCII 码，那么正则表达式可以轻松地实现：

	$sentence = 'here is some text where i would like the first letter to be capitalized.'
	$pattern = '\b(\w)'
	[RegEx]::Replace($sentence, $pattern, { param($x) [Byte][Char]$x.Value })
 
<!--more-->
本文国际来源：[Capitalizing Words](http://community.idera.com/powershell/powertips/b/tips/posts/capitalizing-words)
