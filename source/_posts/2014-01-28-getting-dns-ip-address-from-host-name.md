---
layout: post
title: "PowerShell 技能连载 - 根据主机名获取 DNS IP 地址"
date: 2014-01-28 00:00:00
description: PowerTip of the Day - Getting DNS IP Address from Host Name
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有一个 `GetHostByName()` .NET 函数十分有用。它可以查询一个主机名并返回其当前的 IP 地址：

	[System.Net.DNS]::GetHostByName('someName')

通过一个简单的 PowerShell 包装，它可以转换成一个多功能的很棒的小函数：

	function Get-IPAddress
	{
	  param
	  (
	    [Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
	    [String[]]
	    $Name
	  )
	
	  process
	  { $Name | ForEach-Object { try { [System.Net.DNS]::GetHostByName($_) } catch { } }}
	}

您现在可以直接使用这个函数（来获取您的 IP 地址）了。您可以传入一个或多个计算机名（逗号分隔）。您甚至可以通过 `Get-ADComputer` 或者 `Get-QADComputer` 管道传入数据。

	Get-IPAddress
	Get-IPAddress -Name TobiasAir1
	Get-IPAddress -Name TobiasAir1, Server12, Storage1
	'TobiasAir1', 'Server12', 'Storage1' | Get-IPAddress
	Get-QADComputer | Get-IPAddress
	Get-ADComputer -Filter * | Get-IPAddress

这样做是可行的，因为这个函数包含管道绑定以及一个参数序列化器。

`-Name` 参数为 `ForEach-Object` 提供数据，所以无论用户传入多少个机器名，它们都能被正确处理。

`-Name` 参数既能以参数的方式，也能以值的方式从管道中接收数据。所以您可以传入任何包含“Name”属性的对象，也可以传入任何纯字符串的列表。

注意该函数有一个非常简易的错误处理器。如果您传入了一个无法解析的计算机名，那么什么事也不会发生。如果您需要处理错误信息，请在 catch 代码块中添加代码。

<!--本文国际来源：[Getting DNS IP Address from Host Name](http://community.idera.com/powershell/powertips/b/tips/posts/getting-dns-ip-address-from-host-name)-->
