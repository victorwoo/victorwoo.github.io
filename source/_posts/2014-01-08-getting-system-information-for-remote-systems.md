layout: post
title: "PowerShell 技能连载 - 获取远程主机的系统信息"
date: 2014-01-08 00:00:00
description: PowerTip of the Day - Getting System Information for Remote Systems
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
在上一个技巧当中您已学到如何用 systeminfo.exe 获取丰富的系统资料。systeminfo.exe 内置了远程的功能，所以如果您拥有了适当的权限，您可以获取远程主机的系统信息。

以下是一个简单的函数：

	function Get-SystemInfo
	{
	  param($ComputerName = $env:ComputerName)
	
	      $header = 'Hostname','OSName','OSVersion','OSManufacturer','OSConfig','Buildtype',`'RegisteredOwner','RegisteredOrganization','ProductID','InstallDate','StartTime','Manufacturer',`'Model','Type','Processor','BIOSVersion','WindowsFolder','SystemFolder','StartDevice','Culture',`'UICulture','TimeZone','PhysicalMemory','AvailablePhysicalMemory','MaxVirtualMemory',`'AvailableVirtualMemory','UsedVirtualMemory','PagingFile','Domain','LogonServer','Hotfix',`'NetworkAdapter'
	      systeminfo.exe /FO CSV /S $ComputerName |
	            Select-Object -Skip 1 |
	            ConvertFrom-CSV -Header $header
	}

以下是简单的调用示例：

![](/img/2014-01-08-getting-system-information-for-remote-systems-001.png)


<!--more-->
本文国际来源：[Getting System Information for Remote Systems](http://community.idera.com/powershell/powertips/b/tips/posts/getting-system-information-for-remote-systems)
