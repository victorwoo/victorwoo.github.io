layout: post
title: "用 PowerShell 脚本获取天气实况"
date: 2013-11-12 00:00:00
description: Get Real Time Weather Report by PowerShell
categories: powershell
tags:
- powershell
- geek
---
只要两行命令，就可以“轻松”地获取实时天气预报：

	(curl http://61.4.185.48:81/g/ -UseBasicParsing).Content -cmatch 'var id=(\d+);' | Out-Null
	irm "http://www.weather.com.cn/data/sk/$($matches[1]).html" | select -exp weatherinfo

使用效果：

	PS >(curl http://61.4.185.48:81/g/ -UseBasicParsing).Content -cmatch 'var id=(\d+);' | Out-Null
	PS >irm "http://www.weather.com.cn/data/sk/$($matches[1]).html" | select -exp weatherinfo
	
	
	city    : 福州
	cityid  : 101230101
	temp    : 15
	WD      : 北风
	WS      : 2级
	SD      : 79%
	WSE     : 2
	time    : 10:20
	isRadar : 1
	Radar   : JC_RADAR_AZ9591_JB

您还可以把第二行改为以下形式，获取更猛的数据：

	irm "http://m.weather.com.cn/data/$($matches[1]).html" | select -exp weatherinfo

或：

	irm "http://www.weather.com.cn/data/cityinfo/$($matches[1]).html" | select -exp weatherinfo

[源代码下载](/assets/download/Get-Weather.ps1)

顺便透露一下，高富帅一般不这么看天气预报哦！
