layout: post
title: "PowerShell 技能连载 - 检查管理员权限"
date: 2013-09-24 00:00:00
description: PowerTip of the Day - Testing Administrator Privileges
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
以下通过一个非常规的办法实现检查一段脚本是否以管理员权限运行（通过提升UAC），这体现了PowerShell强大的灵活性：

	function Test-Admin { [bool]((whoami /groups) -match "S-1-16-12288") }

它的基本原理是检查当前用户是否是**高完整性级别**用户组的成员。该用户组是专门针对提升权限的管理员设置的。

如果您不想使用本地命令（whoami.exe）的话，还可以使用更贴近PowerShell（或.NET）的方法，如以下代码所示：

	function Test-Admin {
	
		$id = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
	
		$id.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
	
	}

<!--more-->

本文国际来源：[Testing Administrator Privileges](http://community.idera.com/powershell/powertips/b/tips/posts/testing-administrator-privileges)
