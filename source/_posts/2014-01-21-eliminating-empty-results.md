layout: post
title: "PowerShell 技能连载 - 删除空结果"
date: 2014-01-21 00:00:00
description: PowerTip of the Day - Eliminating Empty Results
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
要排除某些包含空属性值的结果，您可以简单地使用 `Where-Object` 命令。例如，当您运行 `Get-HotFix` 时，假设您只希望查看 `InstalledOn` 属性包含时间值的补丁，以下是解决方案：

	PS> Get-HotFix | Where-Object InstalledOn

类似地，要从 WMI 中获取分配了 IP 地址的网络适配器，请使用以下代码：

	PS> Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object IPAddress

请注意在 PowerShell 2.0 以及以下版本，您需要使用完整的语法，类似如下：

	PS> Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.IPAddress }

`Where-Object` 将会排除您所选的属性包含以下任意一种情况的对象：null 值、空字符串，或者数字 0。因为这些值在转换为 `Boolean` 类型的时候将会被转换成 `$false`。

<!--more-->
本文国际来源：[Eliminating Empty Results](http://community.idera.com/powershell/powertips/b/tips/posts/eliminating-empty-results)
