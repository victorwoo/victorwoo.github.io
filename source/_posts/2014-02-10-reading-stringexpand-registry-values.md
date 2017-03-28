layout: post
title: "PowerShell 技能连载 - 读取注册表的可扩充字符串值"
date: 2014-02-10 00:00:00
description: PowerTip of the Day - Reading StringExpand Registry Values
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
当您读取一个“可扩充字符串”类型的注册表值时，它将自动展开文本中的所有环境变量值。

这个例子将从注册表中读取系统设备路径：

	$path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion'
	$key = Get-ItemProperty -Path $path
	$key.DevicePath

该结果将是实际的路径。这问题不大，除非您希望获取原始（未展开的）注册表值。以下是读取原始值的例子：

	$path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion'
	$key = Get-Item -Path $path
	$key.GetValue('DevicePath', '', 'DoNotExpandEnvironmentNames')

通过这种方式存取注册表值可以提供额外的信息：您还可以获取该值的数据类型：

	$path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion'
	$key = Get-Item -Path $path
	$key.GetValueKind('DevicePath')

<!--more-->
本文国际来源：[Reading StringExpand Registry Values](http://community.idera.com/powershell/powertips/b/tips/posts/reading-stringexpand-registry-values)
