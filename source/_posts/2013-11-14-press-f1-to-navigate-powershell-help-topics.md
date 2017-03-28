layout: post
title: "PowerShell 技能连载 - 按 F1 跳转到 PowerShell 帮助主题"
date: 2013-11-14 00:00:00
description: PowerTip of the Day - Press F1 to Navigate PowerShell Help Topics
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
要在 PowerShell 3.0 ISE 编辑器中获得 PowerShell 所有类型的操作符帮助信息，首先列出关于操作符的所有帮助主题： 

	help operators

您将会见到一个类似这样的列表：

	PS> help operators
	
	Name                              Category  Module                    Synopsis
	----                              --------  ------                    --------
	about_Arithmetic_Operators        HelpFile                            SHORT DESCRIPTION
	about_Assignment_Operators        HelpFile                            SHORT DESCRIPTION
	about_Comparison_Operators        HelpFile                            SHORT DESCRIPTION
	about_Logical_Operators           HelpFile                            SHORT DESCRIPTION
	about_Operators                   HelpFile                            SHORT DESCRIPTION
	about_Type_Operators              HelpFile                            SHORT DESCRIPTION

如果您没有看见这个列表，您也许需要先下载 PowerShell 帮助文档。请通过 `Update-Help` 来查看方法！

然后，单击其中的任意一个主题，然后按下 `F1` 键。帮助窗口将会打开，并显示详细的帮助。
<!--more-->
本文国际来源：[Press F1 to Navigate PowerShell Help Topics](http://community.idera.com/powershell/powertips/b/tips/posts/press-f1-to-navigate-powershell-help-topics)
