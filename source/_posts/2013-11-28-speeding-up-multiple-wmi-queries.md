---
layout: post
title: "PowerShell 技能连载 - 加速多个 WMI 查询"
date: 2013-11-28 00:00:00
description: PowerTip of the Day - Speeding Up Multiple WMI Queries
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您远程执行 `Get-WmiObject` 命令时，它将会创建一个新的连接。所以如果您查询不同的 WMI 类时，每个查询会使用一个不同的连接，这样将会影响总体性能。 

从 PowerShell 3.0 开始，有一些列新的 Cmdlet。使用这些 Cmdlet 可以容易地使用现有的连接高效地运行多个查询：

	$session = New-CimSession –ComputerName localhost
	$os = Get-CimInstance –ClassName Win32_OperatingSystem –CimSession $session
	$bios = Get-CimInstance -ClassName Win32_BIOS -CimSession $session

会话缺省使用 WSMAN 协议：

	PS> $session
	
	Id           : 1
	Name         : CimSession1
	InstanceId   : 0bb38128-3633-4eb8-8b55-6d2910b89bcd
	ComputerName : localhost
	Protocol     : WSMAN

当您创建会话是，您可以显式地指定一个不同的远程传输协议，例如 DCOM。

<!--本文国际来源：[Speeding Up Multiple WMI Queries](http://community.idera.com/powershell/powertips/b/tips/posts/speeding-up-multiple-wmi-queries)-->
