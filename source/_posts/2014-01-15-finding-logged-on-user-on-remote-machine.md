layout: post
title: "PowerShell 技能连载 - 查找远程计算机上已登录的用户"
date: 2014-01-15 00:00:00
description: PowerTip of the Day - Finding Logged-On User on Remote Machine
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
在上一个技巧当中我们使用 quser.exe 来查询本机当前登录的用户。以下是一个支持查询远程计算机上已登录用户的函数。有个额外的好处是，返回的信息附加了一个名为“ComputerName”的属性，所以当您查询多台计算机时，您将可以知道结果是属于那一台计算机的：

	function Get-LoggedOnUser
	{
	  param([String[]]$ComputerName = $env:COMPUTERNAME)
	
	    $ComputerName | ForEach-Object {
	      (quser /SERVER:$_) -replace '\s{2,}', ',' |
	        ConvertFrom-CSV |
	        Add-Member -MemberType NoteProperty -Name ComputerName -Value $_ -PassThru
	  }
	}

以下是一个调用的例子，查询本地计算机以及一台远程计算机：

![](/img/2014-01-15-finding-logged-on-user-on-remote-machine-001.png)

<!--more-->
本文国际来源：[Finding Logged-On User on Remote Machine](http://community.idera.com/powershell/powertips/b/tips/posts/finding-logged-on-user-on-remote-machine)
