---
layout: post
title: "PowerShell 技能连载 - 查找缺省的 Outlook 配置文件"
date: 2013-11-06 00:00:00
description: PowerTip of the Day - Finding Default Outlook Profile
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
PowerShell 可以操作 COM 对象，例如 Outlook 应用程序。以下简单的两行代码能返回当前的 Outlook 配置文件名：

	$outlookApplication = New-Object -ComObject Outlook.Application
	$outlookApplication.Application.DefaultProfileName 

<!--more-->
本文国际来源：[Finding Default Outlook Profile](http://community.idera.com/powershell/powertips/b/tips/posts/finding-default-outlook-profile)
