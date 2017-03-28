layout: post
title: "用一句话定义 PowerShell"
date: 2014-03-23 00:00:00
description: Define PowerShell in Thirty Words or Less
categories: powershell
tags:
- powershell
- language
---
**摘要**：微软脚本小子 Ed Wilson，提供了对 Windows PowerShell 的一句话描述，并且证明了它不超过 30 个单词。

问：如何用一句话定义 Windows PowerShell？

答：Windows PowerShell 是微软公司开发的下一代命令行和脚本语言，它在多数环境下可以替代 vbscript 和 cmd 命令行。

问：您如何确定这句话不超过 30 个单词？

答：用以下代码：

	$a = "Windows PowerShell is the next generation cmd prompt and scripting language from Microsoft. It can be a replacement for vbscript and for the cmd prompt in most circumstances."
	
	Measure-Object -InputObject $a -Word

原文：
## PowerTip: Define PowerShell in Thirty Words or Less
**Summary**: Microsoft Scripting Guy, Ed Wilson, offers a quick thirty-word description of Windows PowerShell, and he proves it.

Q: What is Windows PowerShell in thirty words or less?

A: Windows PowerShell is the next generation cmd prompt and scripting language from Microsoft. It can be a replacement for vbscript and for the cmd prompt in most circumstances.

Q: How can you be sure that was thirty words or less?

A: By using the following code:

	$a = "Windows PowerShell is the next generation cmd prompt and scripting language from Microsoft. It can be a replacement for vbscript and for the cmd prompt in most circumstances."
	
	Measure-Object -InputObject $a -Word

[本文国际来源](http://i1.blogs.technet.com/b/heyscriptingguy/archive/2012/08/12/powertip-define-powershell-in-thirty-words-or-less.aspx)
