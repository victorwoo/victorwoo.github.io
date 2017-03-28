layout: post
title: "快速替换文本文件中的字符串"
date: 2013-10-08 00:00:00
description: Quickly Replace Strings in Text Files
categories: powershell
tags:
- powershell
- script
- geek
---
不用开什么vim、emac、UltraEdit、Eclipse之类的编辑器了，PowerShell可以帮助手无寸铁的您快速地替换文本文件中的字符串：

	dir *.txt -Recurse | % {
	    (gc $_ -Raw) | % { $_ `
	        -creplace '111', 'AAA' `
	        -creplace '222', 'BBB' `
	        -creplace '333', 'CCC'
	    } | sc $_
	}

注意 `-creplace` 区分大小写，`-replace` 不区分大小写。并且它们支持正则表达式！
