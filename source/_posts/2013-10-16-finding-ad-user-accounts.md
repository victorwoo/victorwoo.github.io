layout: post
title: "PowerShell 技能连载 - 查找 Active Directory 用户账号"
date: 2013-10-16 00:00:00
description: PowerTip of the Day - Finding AD User Accounts
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
有很多用于 Active Directory 的 Module 和 Cmdlet，但是有些时候用 .NET 代码来做反而更方便快捷。

比如说，如果您只是想知道，某个用户是否存在于您的 Active Directory中，那么实现查找一个用户是很容易的：

	# sending LDAP query to Active Directory
	$searcher = [ADSISearcher]'(&(objectClass=User)(objectCategory=person)(SamAccountName=tobias*))'
	# finding first match
	$searcher.FindOne()
	# finding ALL matches
	$searcher.FindAll() 

这段代码将查找所有 SamAccountName 以 "tobias" 开头的用户账号。您可以接着用这个方法来便捷地找出这个用户所在的位置：

	# find account location
	$searcher.FindAll() | Select-Object -ExpandProperty Path

<!--more-->

本文国际来源：[Finding AD User Accounts](http://community.idera.com/powershell/powertips/b/tips/posts/finding-ad-user-accounts)
