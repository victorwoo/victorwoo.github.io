layout: post
title: "PowerShell 技能连载 - PowerShell 远程管理和大尺寸令牌问题"
date: 2014-01-01 00:00:00
description: PowerTip of the Day - PowerShell Remoting with Large Token Size
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
Kerberos 令牌大小取决于用户组成员的数量。在某些重度使用组成员的企业环境中，令牌的大小可能会溢出 PowerShell 远程管理的限制。在这些情况下，PowerShell 远程管理操作会失败，提示一句模糊的信息。

要使用 PowerShell 远程管理，您可以设置两个注册表值，并且增加令牌的允许尺寸：

	#Source: http://www.miru.ch/how-the-kerberos-token-size-can-affect-winrm-and-other-kerberos-based-services/
	New-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\HTTP\Parameters `-Name "MaxFieldLength" -Value 65335 -PropertyType "DWORD"
	New-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\HTTP\Parameters `-Name "MaxRequestBytes" -Value 40000 -PropertyType "DWORD"

<!--more-->
本文国际来源：[PowerShell Remoting with Large Token Size](http://community.idera.com/powershell/powertips/b/tips/posts/powershell-remoting-with-large-token-size)
