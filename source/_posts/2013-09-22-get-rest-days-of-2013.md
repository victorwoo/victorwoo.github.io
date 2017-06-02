---
layout: post
title: "获取2013年剩余天数"
date: 2013-09-22 00:00:00
description: Get rest days of 2013
categories: powershell
tags:
- powershell
- script
- geek
---
用PowerShell获取2013年剩余天数的两种写法。

	((Get-Date 2014-1-1) - (Get-Date)).Days
	100

	([datetime]"2014-1-1" - [datetime]::now).Days
	100

顺便励志一下，2013年只剩下100天了。Come on，小伙伴们！
