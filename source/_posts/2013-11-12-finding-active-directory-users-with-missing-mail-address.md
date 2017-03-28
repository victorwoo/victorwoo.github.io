layout: post
title: "PowerShell 技能连载 - 查找缺少邮箱地址的 Active Directory 用户"
date: 2013-11-12 00:00:00
description: PowerTip of the Day - Finding Active Directory Users with Missing Mail Address
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
LDAP 查询的功能非常强大，可以帮助查找缺少信息的账户。

这段代码将返回所有带邮箱地址的 Active Directory 用户：

	$searcher = [ADSISearcher]"(&(sAMAccountType=$(0x30000000))(mail=*))"
	$searcher.FindAll() |
	  ForEach-Object { $_.GetDirectoryEntry() } |
	  Select-Object -Property sAMAccountName, name, mail

如果您想查询相反的内容，请通过“`!`”号进行相反的查询。以下代码可以返回所有缺少邮箱地址的 Active Directory 用户：

	$searcher = [ADSISearcher]"(&(sAMAccountType=$(0x30000000))(!(mail=*)))"
	$searcher.FindAll() |
	  ForEach-Object { $_.GetDirectoryEntry() } |
	  Select-Object -Property sAMAccountName, name, mail

<!--more-->
本文国际来源：[Finding Active Directory Users with Missing Mail Address](http://community.idera.com/powershell/powertips/b/tips/posts/finding-active-directory-users-with-missing-mail-address)
