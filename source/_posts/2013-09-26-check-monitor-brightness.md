---
layout: post
title: "PowerShell 技能连载 - 检测显示器亮度"
date: 2013-09-26 00:00:00
description: PowerTip of the Day - Check Monitor Brightness
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
如果您想检查您当前的显示器亮度（当然，尤其是针对笔记本电脑），以下是一个快捷的函数：

	function Get-MonitorBrightness
	{
	    param($ComputerName, $Credential)
	
	    Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightness @PSBoundParameters | 
	        Select-Object -Property PSComputerName, CurrentBrightness, Levels
	}

它甚至支持 `-ComputerName` 和 `-Credential`，所以您也可以查询远程的主机。

如果您为 `-ComputerName` 参数传入一个用逗号分隔的主机名或IP地址列表，您将获得所有具有**local Admin**权限的主机的执行结果。
<!--more-->

本文国际来源：[Check Monitor Brightness](http://community.idera.com/powershell/powertips/b/tips/posts/check-monitor-brightness)
