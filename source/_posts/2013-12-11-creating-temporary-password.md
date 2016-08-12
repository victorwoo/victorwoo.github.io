layout: post
title: "PowerShell 技能连载 - 创建临时密码"
date: 2013-12-11 00:00:00
description: PowerTip of the Day - Creating Temporary Password
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
以下是一些为您创建不同长度随机密码的代码:

	$length = 8
	$characters = [Char[]]((31..50) + (65..90) + (97..122))
	$characters = $characters -ne 'O' -ne 'o' -ne 'l' -ne '1' -ne '-'
	$password = -join ($characters | Get-Random -Count $length)
	"Your temporary $length-character-password is $password"

您的密码长度通过 `$length` 变量设置。用于构成密码的字符集存放在 `$characters` 变量中。缺省情况下使用 ASCII 编码为 31-50、65-90、97-122 的所有字符。如您所见，通过 `-ne` 操作符，您可以调整列表和排除字符。在我们的例子中，我们排除了容易拼写错的字母。

<!--more-->
本文国际来源：[Creating Temporary Password](http://powershell.com/cs/blogs/tips/archive/2013/12/11/creating-temporary-password.aspx)
