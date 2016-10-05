layout: post
title: "PowerShell 技能连载 - PowerShell 4.0 中的动态参数"
date: 2013-11-04 00:00:00
description: PowerTip of the Day - Dynamic Parameters in PowerShell 4.0
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
在 PowerShell 中，您可以使用变量来指代属性名。这段示例脚本定义了四个 profile 的属性名，然后在一个循环中分别查询这些属性值：

	$list = 'AllUsersAllHosts','AllUsersCurrentHost','CurrentUserAllHosts','CurrentUserCurrentHost'
	foreach ($property in $list)
	{
		$profile.$property
	}

您也可以在一个管道中使用它：

	'AllUsersAllHosts','AllUsersCurrentHost','CurrentUserAllHosts','CurrentUserCurrentHost' |
	ForEach-Object { $profile.$_ } 

通过这种方式，您可以检查和返回 PowerShell 当前使用的所有 profile：

	'AllUsersAllHosts','AllUsersCurrentHost','CurrentUserAllHosts','CurrentUserCurrentHost' |
	ForEach-Object { $profile.$_ } |
	Where-Object { Test-Path $_ } 

类似地，您可以首先使用 `Get-Member` 来获取一个指定对象包含的所有属性。以下代码可以返回 PowerShell 的“PrivateData”对象中所有名字包含“color”的属性：

	$host.PrivateData | Get-Member -Name *color* | Select-Object -ExpandProperty Name 

接下来，您可以用一行代码获取所有的颜色设置：

	$object = $host.PrivateData
	$object | Get-Member -Name *color* -MemberType *property | ForEach-Object {
		$PropertyName = $_.Name
		$PropertyValue = $object.$PropertyName
		"$PropertyName = $PropertyValue"
	} |
	Out-GridView
  
<!--more-->
本文国际来源：[Dynamic Parameters in PowerShell 4.0](http://community.idera.com/powershell/powertips/b/tips/posts/dynamic-parameters-in-powershell-4-0)
