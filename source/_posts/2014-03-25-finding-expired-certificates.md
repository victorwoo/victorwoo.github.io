---
layout: post
title: "PowerShell 技能连载 - 查找过期的证书"
date: 2014-03-25 00:00:00
description: PowerTip of the Day - Finding Expired Certificates
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
PowerShell 通过 `cert:` 驱动器来存取您的证书存储。

您可以根据指定的规则用这个驱动器来查找证书。以下代码将列出所有 `NotAfter` 字段中有值并在今日之前（意味着证书已过期）的证书：

	$today = Get-Date
	
	Get-ChildItem -Path cert:\ -Recurse |
	  Where-Object { $_.NotAfter -ne $null  } |
	  Where-Object { $_.NotAfter -lt $today } |
	  Select-Object -Property FriendlyName, NotAfter, PSParentPath, Thumbprint |
	  Out-GridView

<!--more-->
本文国际来源：[Finding Expired Certificates](http://community.idera.com/powershell/powertips/b/tips/posts/finding-expired-certificates)
