layout: post
title: "PowerShell 技能连载 - 获取时间服务器（以及读取所有注册表键值）"
date: 2014-03-26 00:00:00
description: PowerTip of the Day - Finding Time Servers (And Reading All RegKey Values)
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
也许您希望从注册表数据库中获取已登记的时间服务器列表。他们您可能需要运行类似这样的代码：

	Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\DateTime\Servers'

![](/img/2014-03-26-finding-time-servers-and-reading-all-regkey-values-001.png)

	$path = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\DateTime\Servers'
	
	$key = Get-Item -Path $path
	Foreach ($valuename in $key.GetValueNames())
	{
	  if ($valuename -ne '')
	  {
	    $key.GetValue($valuename)
	  }
	}

这段代码存取注册表键，然后使用它的方法来获取值的名称，然后取出值：

![](/img/2014-03-26-finding-time-servers-and-reading-all-regkey-values-002.png)

<!--more-->
本文国际来源：[Finding Time Servers (And Reading All RegKey Values)](http://community.idera.com/powershell/powertips/b/tips/posts/finding-time-servers-and-reading-all-regkey-values)
