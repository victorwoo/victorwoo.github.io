layout: post
title: "PowerShell 技能连载 - Ping 主机"
date: 2014-01-30 00:00:00
description: PowerTip of the Day - Pinging Computers
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
有很多种方法可供您 ping 主机。以下是一个简单的将传统的 ping.exe 结合进您的脚本的方法：

	function Test-Ping
	{
	    param([Parameter(ValueFromPipeline=$true)]$Name)
	
	    process {
	      $null = ping.exe $Name -n 1 -w 1000
	      if($LASTEXITCODE -eq 0) { $Name }
	    }
	}

`Test-Ping` 接受一个主机名或 IP 地址作为参数并且返回 ping 是否成功。通过这种方法，您可以传入一个大的主机或 IP 地址列表，然后获得在线的结果：

	'??','127.0.0.1','localhost','notthere',$env:COMPUTERNAME | Test-Online

<!--more-->
本文国际来源：[Pinging Computers](http://community.idera.com/powershell/powertips/b/tips/posts/pinging-computers)
