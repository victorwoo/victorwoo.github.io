layout: post
title: "PowerShell 技能连载 - 使用 $PSScriptRoot 加载资源"
date: 2014-02-20 00:00:00
description: PowerTip of the Day - Use $PSScriptRoot to Load Resources
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
从 PowerShell 3.0 开始，有一个称为 `$PSScriptRoot` 的变量可用。该变量之前只在模块中可用。它总是指向当前脚本所在的文件夹（所以它仅在您明确地保存了它以后才生效）。

您可以使用 `$PSScriptRoot` 来加载相对于您脚本位置的额外资源。例如，如果您打算将一些函数放在同一个文件夹中的一个独立的“library”脚本中，以下代码将加载该 library 脚本并且导入它包含的所有函数：

	# this loads the script "library1.ps1" if it is located in the very
	# same folder as this script.
	# Requires PowerShell 3.0 or better.
	
	. "$PSScriptRoot\library1.ps1"

类似地，如果您希望将您的 library 脚本保存在一个子文件夹中，请试验以下脚本（假设库脚本放在您脚本所在文件夹中的“resources”子文件夹下）：

	# this loads the script "library1.ps1" if it is located in the subfolder
	# "resources" in the folder this script is in.
	# Requires PowerShell 3.0 or better.
	
	. "$PSScriptRoot\resources\library1.ps1"

<!--more-->
本文国际来源：[Use $PSScriptRoot to Load Resources](http://powershell.com/cs/blogs/tips/archive/2014/02/20/use-psscriptroot-to-load-resources.aspx)
