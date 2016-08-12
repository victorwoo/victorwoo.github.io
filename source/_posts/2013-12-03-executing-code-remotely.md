layout: post
title: "PowerShell 技能连载 - 远程执行代码"
date: 2013-12-03 00:00:00
description: PowerTip of the Day - Executing Code Remotely
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
在一个域环境中，PowerShell 远程操作功能几乎是开箱即用的。您所需要做的知识在目标机器上启用远程功能（从 Server 2012 开始，PowerShell 远程操作功能对于 Administrators 组用户缺省是启用的）。

在 PowerShell 3.0 中，需要人为地启用远程功能，这就是一切要做的事了（需要管理员权限）：

	PS> Enable-PSRemoting -SkipNetworkProfileCheck -Force

你不需要在客户端（准备发送命令的机器）上配置任何东西。

下一步，任何管理员可以将命令发送到启用了远程操作功能的机器上去执行它。以下例子将列出目标机器上所有和 PowerShell 相关的进程：

	$code =
	{
	      Get-Process -Name powershell*, wsmprovhost -ErrorAction SilentlyContinue
	}
	
	$list = 'server1', 'w2k12-niki', 'pc11box'
	Invoke-Command -ScriptBlock $code #-ComputerName $list

当您原样执行这段代码的时候，`Invoke-Command` 在您自己的机器上运行存储在 `$code` 中的代码块。

![](/img/2013-12-03-executing-code-remotely-001.png)

它列出所有运行中的 PowerShell 控制台的实例、ISE PowerShell 编辑器，以及所有由您机器上别人初始化的 PowerShell 隐藏远程会话。

而当您去掉 `-ComputerName` 参数的注释，代码将会在 `$list` 变量存储的所有计算机上执行。请确保它们存在并且已启用了远程操作功能。当您从远程计算机收到数据时，PowerShell 自动在返回的信息上附加一个 `"PSComputerName"` 属性，用来存储返回信息的计算机名。

<!--more-->
本文国际来源：[Executing Code Remotely](http://powershell.com/cs/blogs/tips/archive/2013/12/03/executing-code-remotely.aspx)
