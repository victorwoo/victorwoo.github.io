---
layout: post
title: "PowerShell 技能连载 - 将二进制 SID 转换为 SID 字符串"
date: 2013-10-21 00:00:00
description: PowerTip of the Day - Converting Binary SID to String SID
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Active Directory 账户有一个二进制形式存储的 SID。要将字节数组转换为字符串的表达形式，可以用如下的 .NET 函数：

	# get current user
	$searcher = [ADSISearcher]"(&(objectClass=User)(objectCategory=person)(sAMAccountName=$env:username))"
	$user = $searcher.FindOne().GetDirectoryEntry() 
	
	# get binary SID from AD account
	$binarySID = $user.ObjectSid.Value
	
	# convert to string SID
	$stringSID = (New-Object System.Security.Principal.SecurityIdentifier($binarySID,0)).Value
	
	$binarySID
	$stringSID 

在这个例子中，一个 ADSI 搜索器获取当前的用户账户（返回当前登录到一个域中的用户）。然后，将二进制的 SID 转换为 SID 字符串。

<!--本文国际来源：[Converting Binary SID to String SID](http://community.idera.com/powershell/powertips/b/tips/posts/converting-binary-sid-to-string-sid)-->
