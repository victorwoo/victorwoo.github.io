layout: post
title: "PowerShell 技能连载 - 查找 U 盘信息"
date: 2014-03-27 00:00:00
description: PowerTip of the Day - Finding USB Stick Information
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
您知道吗，Windows 记录了您使用过的所有 U 盘信息。要从注册表中读取上述信息，只需要使用这个函数：

	function Get-USBInfo
	{
	  param
	  (
	    $FriendlyName = '*'
	  )
	
	  Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USBSTOR\*\*\' |
	  Where-Object { $_.FriendlyName } |
	  Where-Object { $_.FriendlyName -like $FriendlyName } |
	  Select-Object -Property FriendlyName, Mfg |
	  Sort-Object -Property FriendlyName
	}

以下是输出的例子：

![](/img/2014-03-27-finding-usb-stick-information-001.png)

您还可以按厂商来查询：

![](/img/2014-03-27-finding-usb-stick-information-002.png)

<!--more-->
本文国际来源：[Finding USB Stick Information](http://powershell.com/cs/blogs/tips/archive/2014/03/27/finding-usb-stick-information.aspx)
