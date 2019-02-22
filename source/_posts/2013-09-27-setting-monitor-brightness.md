---
layout: post
title: "PowerShell 技能连载 - 设置显示器亮度"
date: 2013-09-27 00:00:00
description: PowerTip of the Day - Check Monitor Brightness
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您的显示驱动程序支持WMI，那么您可以用PowerShell改变显示器的亮度——甚至是远程的计算机！

以下是实现改变显示器亮度的函数：

	function Set-MonitorBrightness
	{
	    param
	    (
	        [Parameter(Mandatory=$true)]
	        [Int][ValidateRange(0,100)]
	        $Value,
	
	        $ComputerName, 
	        $Credential
	    )
	
	    $null = $PSBoundParameters.Remove('Value')
	
	    $helper = Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightnessMethods @PSBoundParameters 
	    $helper.WmiSetBrightness(1, $Value)
	}

只需要指定一个0-100之间的值，您就可以看到显示器亮度发生改变。为 `-ComputerName` 参数指定远程计算机名或IP地址（均支持多个），然后您远程的同事们会惊讶地发现去吃午餐的时候显示器都变暗了！当然，远程操作WMI需要本地管理员权限，并且为防火墙设置了允许远程管理的规则。

如果提示“不支持”的错误提示信息，那么说明您的显示驱动程序不支持WMI。

这是“有趣”的部分：模拟一个古怪的显示效果：

	for($x=0; $x -lt 20; $x++)
	{    
	    Set-MonitorBrightness -Value (Get-Random -Minimum 20 -Maximum 101)  
	    Start-Sleep -Seconds 1    
	}


<!--本文国际来源：[Setting Monitor Brightness](http://community.idera.com/powershell/powertips/b/tips/posts/setting-monitor-brightness)-->
