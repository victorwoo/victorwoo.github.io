layout: post
title: "PowerShell 技能连载 - 为对象增加信息"
date: 2014-02-28 00:00:00
description: PowerTip of the Day - Tag Your Objects with Additional Information
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
有时会遇到这样的需求：需要向命令的执行结果增加额外的信息。也许您从不同的机器获取信息，并且希望保存数据来源的引用。或者，您也许希望增加一个日期，以便知道数据是何时创建的。

向对象附加信息（增加额外的信息列）是很简单的。这段代码将为一个服务列表增加新的“SourceComputer”属性以及日期。

	Get-Service |
	  Add-Member -MemberType NoteProperty -Name SourceComputer -Value $env:COMPUTERNAME -PassThru |
	  Add-Member -MemberType NoteProperty -Name Date -Value (Get-Date) -PassThru |
	  Select-Object -Property Name, Status, SourceComputer, Date

请记着您新增的属性需要在使用 `Select-Object` 以及显式地要求显式它们的时候，才会在结果中显示出来。

<!--more-->
本文国际来源：[Tag Your Objects with Additional Information](http://community.idera.com/powershell/powertips/b/tips/posts/tag-your-objects-with-additional-information)
