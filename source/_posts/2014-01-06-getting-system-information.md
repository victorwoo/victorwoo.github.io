layout: post
title: "PowerShell 技能连载 - 获取系统信息"
date: 2014-01-06 00:00:00
description: PowerTip of the Day - Getting System Information
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
PowerShell 和现有的控制台程序可以很好地共存。一个最有用的是 systeminfo.exe，它可以收集各种有用的系统信息。通过导入 systeminfo.exe 提供的 CSV 信息，PowerShell 可以将文本信息转化为对象：

	$header = 'Hostname','OSName','OSVersion','OSManufacturer','OSConfig','Buildtype',`'RegisteredOwner','RegisteredOrganization','ProductID','InstallDate','StartTime','Manufacturer',`'Model','Type','Processor','BIOSVersion','WindowsFolder','SystemFolder','StartDevice','Culture',`'UICulture','TimeZone','PhysicalMemory','AvailablePhysicalMemory','MaxVirtualMemory',`'AvailableVirtualMemory','UsedVirtualMemory','PagingFile','Domain','LogonServer','Hotfix',`'NetworkAdapter'
	
	systeminfo.exe /FO CSV |   Select-Object -Skip 1 |   ConvertFrom-CSV -Header $header

当您运行这段代码时，它将停顿数秒钟，以供 systeminfo.exe 收集信息。然后，您将会获得大量的信息：

![](/img/2014-01-06-getting-system-information-001.png)

请注意 `$header`：这个变量定义了属性名称，并且用自定义的列表替换了缺省的表头。所以，无论操作系统是哪种语言的，这些表头永远是相同的。

您还可以将这些信息存储在一个变量中，然后分别存取其中的信息：

	$header = 'Hostname','OSName','OSVersion','OSManufacturer','OSConfig','Buildtype',`'RegisteredOwner','RegisteredOrganization','ProductID','InstallDate','StartTime','Manufacturer',`'Model','Type','Processor','BIOSVersion','WindowsFolder','SystemFolder','StartDevice','Culture',`'UICulture','TimeZone','PhysicalMemory','AvailablePhysicalMemory','MaxVirtualMemory',`'AvailableVirtualMemory','UsedVirtualMemory','PagingFile','Domain','LogonServer','Hotfix',`'NetworkAdapter'
	
	$result = systeminfo.exe /FO CSV |
	  Select-Object -Skip 1 |
	  ConvertFrom-CSV -Header $header

![](/img/2014-01-06-getting-system-information-002.png)

<!--more-->
本文国际来源：[Getting System Information](http://community.idera.com/powershell/powertips/b/tips/posts/getting-system-information)
