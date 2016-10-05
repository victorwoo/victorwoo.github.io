layout: post
title: "PowerShell 技能连载 - 从 DN 中获得 Domain"
date: 2013-10-22 00:00:00
description: PowerTip of the Day - Getting Domain from DN
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
"DN" 指的是是 Active Directory 对象的路径，看起来大概如下：

	'CN=Tobias,OU=Authors,DC=powershell,DC=local'

要获取 DN 中的域部分，请使用如下代码：

	$DN = 'CN=Tobias,OU=Authors,DC=powershell,DC=local'
	$pattern = '(?i)DC=\w{1,}?\b'
	
	([RegEx]::Matches($DN, $pattern) | ForEach-Object { $_.Value }) -join ',' 

这段代码用一个正则表达式来查找 DN 的所有 `DC=` 部分；然后将它们用逗号分隔符连接起来。

执行结果如下：

	DC=powershell,DC=local

<!--more-->
本文国际来源：[Getting Domain from DN](http://community.idera.com/powershell/powertips/b/tips/posts/getting-domain-from-dn)
