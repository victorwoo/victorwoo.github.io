---
layout: post
title: "PowerShell 技能连载 - 搜索本地用户"
date: 2013-12-23 00:00:00
description: PowerTip of the Day - Searching for Local User Accounts
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
您知道吗？您可以搜索计算机上的本地用户，就像搜索域账户一样。

以下的示例代码搜索所有以“A”开头并且是启用状态的本地用户：

	Add-Type -AssemblyName System.DirectoryServices.AccountManagement
	
	$type = New-Object -TypeName System.DirectoryServices.AccountManagement.PrincipalContext('Machine', $env:COMPUTERNAME)
	
	$UserPrincipal = New-Object System.DirectoryServices.AccountManagement.UserPrincipal($type)
	
	# adjust your search criteria here:
	$UserPrincipal.Name = 'A*'
	# you can add even more:
	$UserPrincipal.Enabled = $true
	
	$searcher = New-Object System.DirectoryServices.AccountManagement.PrincipalSearcher
	$searcher.QueryFilter = $UserPrincipal
	$results = $searcher.FindAll();
	
	$results | Select-Object -Property Name, LastLogon, Enabled

类似地，要查找所有设置了密码、密码永不过期，并且是启用状态的本地用户，试试以下代码：

	Add-Type -AssemblyName System.DirectoryServices.AccountManagement
	
	$type = New-Object -TypeName System.DirectoryServices.AccountManagement.PrincipalContext('Machine', $env:COMPUTERNAME)
	
	$UserPrincipal = New-Object System.DirectoryServices.AccountManagement.UserPrincipal($type)
	
	# adjust your search criteria here:
	$UserPrincipal.PasswordNeverExpires = $true
	$UserPrincipal.Enabled = $true
	
	$searcher = New-Object System.DirectoryServices.AccountManagement.PrincipalSearcher
	$searcher.QueryFilter = $UserPrincipal
	$results = $searcher.FindAll();
	
	$results | Select-Object -Property Name, LastLogon, Enabled, PasswordNeverExpires

<!--more-->
本文国际来源：[Searching for Local User Accounts](http://community.idera.com/powershell/powertips/b/tips/posts/searching-for-local-user-accounts)
