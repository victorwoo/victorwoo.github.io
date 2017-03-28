layout: post
title: "PowerShell 技能连载 - 通过 SID 查找 Active Directory 账户"
date: 2013-10-24 00:00:00
description: PowerTip of the Day - Finding Active Directory Accounts by SID
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
如果您已知账户的 SID 并且希望找到相应的 Active Directory 账户，那么 LDAP 查询并不适合这项工作。为了使它能工作，您需要将 SID 的格式改成符合 LDAP 规则的格式，这不是一个简单的过程。

以下是一个更简单的使用 LDAP 路径的办法。假设您使用 $SID 变量保存了一个 SID 字符串，并且您希望查找出和它关联的 Active Directory 账户。试试以下的代码：

	$SID = '<enter SID here>'   # like S-1-5-21-1234567-...
	$account = [ADSI]"LDAP://<SID=$SID>"
	$account
	$account.distinguishedName
 
<!--more-->
本文国际来源：[Finding Active Directory Accounts by SID](http://community.idera.com/powershell/powertips/b/tips/posts/finding-active-directory-accounts-by-sid)
