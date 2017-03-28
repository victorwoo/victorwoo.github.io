layout: post
title: "PowerShell 技能连载 - 获取 Active Directory 账户信息"
date: 2013-10-17 00:00:00
description: PowerTip of the Day - Getting Active Directory Account Information
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
在上一段脚本中，您应该已经发现了可以多么轻易地用几行 PowerShell 代码来获取 Active Directory 账户。它的结果是一个搜索结果对象，而不是实际的账户对象。

要获取一个账户的更详细信息，请使用 `GetDirectoryEntry()` 将搜索结果转换为一个实际的账户对象：

	# get 10 results max
	$searcher.SizeLimit = 10
	
	# find account location
	$searcher.FindAll() | 
	  # get account object
	  ForEach-Object { $_.GetDirectoryEntry() } |
	  # display all properties
	  Select-Object -Property * |
	  # display in a grid view window (ISE needs to be installed for this step)
	  Out-GridView

<!--more-->

本文国际来源：[Getting Active Directory Account Information](http://community.idera.com/powershell/powertips/b/tips/posts/getting-active-directory-account-information)
