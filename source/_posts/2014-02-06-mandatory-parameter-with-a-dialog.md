---
layout: post
title: "PowerShell 技能连载 - 带对话框的必选参数"
date: 2014-02-06 00:00:00
description: PowerTip of the Day - Mandatory Parameter with a Dialog
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
通常地，当您将一个函数参数标记为“必选的”，如果用户遗漏了这个参数，PowerShell 将提示用户：

	function Get-Something
	{
	      param
	      (
	            [Parameter(Mandatory=$true)]
	            $Path
	      )
	
	      "You entered $Path"
	}

结果如下所示：

	PS> Get-Something
	cmdlet Get-Something at command pipeline position 1
	Supply values for the following parameters:
	Path:

以下是另一种选择：如果用户遗漏了 `-Path`，该函数弹出一个打开文件对话框：

	function Get-Something
	{
	      param
	      (
	            $Path = $(
	              Add-Type -AssemblyName System.Windows.Forms
	              $dlg = New-Object -TypeName  System.Windows.Forms.OpenFileDialog
	              if ($dlg.ShowDialog() -eq 'OK') { $dlg.FileName } else { throw 'No Path submitted'}
	            )
	      )
	
	      "You entered $Path"
	}

<!--more-->
本文国际来源：[Mandatory Parameter with a Dialog](http://community.idera.com/powershell/powertips/b/tips/posts/mandatory-parameter-with-a-dialog)
