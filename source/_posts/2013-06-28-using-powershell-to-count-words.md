layout: post
title: "用PowerShell统计关键词"
date: 2013-06-28 00:00:00
description: using powershell to count words
categories: powershell
tags:
- powershell
- script
---
本来开始打算大干一场的，结果发现区区4行代码搞定了。原来用PowerShell统计关键词这么欢乐啊。
<!--more-->

	$wordBreakers = ",. ()\\/';-<>_#"
	$wordTemplate = '^Pub\w+'
	cd D:\Dropbox\workdir\LandiStore\BOCISTDemo\src\Project
	
	$content = (dir *.c -Recurse | % { cat $_} ) -join "`n"
	$words = $content.Split($wordBreakers)
	$words = $words | ? {$_ -Match $wordTemplate}
	#$words | sort -Unique
	$words | group | sort count -Descending | select Name, Count
