layout: post
title: "PowerShell 技能连载 - 将Out-GridView改造为选择对话框"
date: 2013-09-17 00:00:00
description: PowerTip of the Day - Turn Out-GridView into Selection Dialog
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
在PowerShell 3.0中，`Out-GridView` 终于可以被改为一个多功能选择对话框——只要增加一个新的参数 `-PassThru` 就可以看到效果：

![属性窗口](/img/2013-09-17-turn-out-gridview-into-selection-dialog-001.png)

	$Title = 'Select one or more files to open'
	
	Get-ChildItem -Path $env:windir -Filter *.log |
	  Out-GridView -PassThru -Title $title |
	  ForEach-Object {
	    notepad $_.FullName
	  } 

您可以通过管道将任何对象传给 `Out-GridView`。用户可以从界面中选择输出结果的一部分，或者用关键词过滤结果，然后选择结果的一个或多个元素。点击 OK 之后，选中的元素将传输到下一个命令。
<!--more-->

本文国际来源：[Turn Out-GridView into Selection Dialog](http://community.idera.com/powershell/powertips/b/tips/posts/turn-out-gridview-into-selection-dialog)
