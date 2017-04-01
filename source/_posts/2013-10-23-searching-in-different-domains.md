layout: post
title: "PowerShell 技能连载 - 在不同的 Domain 中查找"
date: 2013-10-23 00:00:00
description: PowerTip of the Day - Searching in Different Domains
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
当你那使用 ADSISearcher 类型加速器来查找 Active Directory 账户时，它缺省情况下在您当前登录的域中查找。如果您需要在一个不同的域中查找，请确保相应地定义了搜索的根路径。

This example will find all accounts with a SamAccountName that starts with "tobias", and it searches the domain "powershell.local" (adjust to a real domain name, of course):
这个例子将查找所有 SamAccountName 以 *"tobias"* 开头的账户，并且它在 *"powershell.local"* 域中搜索（当然，请根据实际情况调整名字）：

	# get all users with a SamAccountName that starts with "tobias"
	$searcher = [ADSISearcher]"(&(objectClass=User)(objectCategory=person)(sAMAccountName=tobias*))"
	
	# use powershell.local for searching
	$domain = New-Object System.DirectoryServices.DirectoryEntry('DC=powershell,DC=local')
	$searcher.SearchRoot = $domain
	
	# execute the query
	$searcher.FindAll() 

<!--more-->
本文国际来源：[Searching in Different Domains](http://community.idera.com/powershell/powertips/b/tips/posts/searching-in-different-domains)
