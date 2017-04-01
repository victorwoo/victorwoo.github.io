layout: post
title: "PowerShell 技能连载 - 处理环境变量"
date: 2014-06-25 00:00:00
description: PowerTip of the Day - Dealing with Environment Variables
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
要在 PowerShell 中读取 Windows 环境变量，只需要使用“env:”前缀：

	PS> $env:windir
	C:\Windows
	
	PS> $env:USERNAME
	Tobias

实际上，“env:”是一个虚拟驱动器，所以您可以用它来查找所有（或一部分）环境变量。这段代码将列出所有名字中含有“user”的环境变量：

	PS> dir env:\*user*
	
	Name                           Value
	----                           -----
	USERPROFILE                    C:\Users\Tobias
	USERNAME                       Tobias
	ALLUSERSPROFILE                C:\ProgramData
	USERDOMAIN                     TobiasAir1

<!--more-->
本文国际来源：[Dealing with Environment Variables](http://community.idera.com/powershell/powertips/b/tips/posts/dealing-with-environment-variables)
