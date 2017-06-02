---
layout: post
title: "PowerShell 技能连载 - 获取最新的地震信息"
date: 2013-12-31 00:00:00
description: PowerTip of the Day - Getting Most Recent Earthquakes
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
现代社会中，所有东西都是彼此相连的。PowerShell 可以从 web service 中获取公共数据。以下仅仅一行代码就可以为您获取最新检测到的地震以及它们的震级：

	Invoke-RestMethod -URI "http://www.seismi.org/api/eqs" |
	  Select-Object -First 30 -ExpandProperty Earthquakes |
	  Out-GridView

<!--more-->
本文国际来源：[Getting Most Recent Earthquakes](http://community.idera.com/powershell/powertips/b/tips/posts/getting-most-recent-earthquakes)
