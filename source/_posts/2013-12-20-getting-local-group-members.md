layout: post
title: "PowerShell 技能连载 - 获取本地组成员"
date: 2013-12-20 00:00:00
description: PowerTip of the Day - Getting Local Group Members
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
在 PowerShell 中，通过 .NET Framework 3.51 或更高的版本，可以使用面向对象的方式管理本地用户和组。以下代码可以列出本机上的管理员用户：

	Add-Type -AssemblyName System.DirectoryServices.AccountManagement
	
	$type = New-Object DirectoryServices.AccountManagement.PrincipalContext('Machine', `$env:COMPUTERNAME)
	
	$group = [DirectoryServices.AccountManagement.GroupPrincipal]::FindByIdentity($type, `'SAMAccountName', 'Administrators')
	
	$group.Members | Select-Object -Property SAMAccountName, LastPasswordSet, LastLogon, Enabled

您还可以获取更多的信息，比如试着查询组本身的信息：
![](/img/2013-12-20-getting-local-group-members-001.png)

或者试着列出所有成员的所有属性：
![](/img/2013-12-20-getting-local-group-members-002.png)
![](/img/2013-12-20-getting-local-group-members-003.png)

<!--more-->
本文国际来源：[Getting Local Group Members](http://community.idera.com/powershell/powertips/b/tips/posts/getting-local-group-members)
