---
layout: post
title: "PowerShell 技能连载 - 获取 1000 个以上 Active Directory 结果"
date: 2013-10-29 00:00:00
description: PowerTip of the Day - Getting More Than 1000 Active Directory Results
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您使用 ADSISearcher 时，默认情况下，Active Directory 只返回前 1000 个搜索结果。这是一个防止意外的 LDAP 查询导致域控制器负荷过重的安全保护机制。

如果您需要完整的搜索结果，并且明确地知道它将超过 1000 条记录，请设置 `PageSize` 为 1000。通过这种方式，ADSISearcher 每一批返回 1000 个搜索结果元素。

以下查询将会返回您域中的所有用户账户（在运行这个查询之前，您也许需要联系一下您的域管理员）：

	$searcher = [ADSISearcher]"sAMAccountType=$(0x30000000)"

	# get all results, do not stop at 1000 results
	$searcher.PageSize = 1000

	$searcher.FindAll() |
	  ForEach-Object { $_.GetDirectoryEntry() } |
	  Select-Object -Property * |
	  Out-GridView

<!--本文国际来源：[Getting More Than 1000 Active Directory Results](http://community.idera.com/powershell/powertips/b/tips/posts/getting-more-than-1000-active-directory-results)-->
