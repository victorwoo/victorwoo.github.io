layout: post
title: "PowerShell 技能连载 - 访问所有用户的桌面"
date: 2013-12-02 00:00:00
description: PowerTip of the Day - Accessing All Users Desktop
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
`Resolve-Path` 是一个相当棒的查找相同深度路径用的 Cmdlet。例如，以下是一段很短小的代码，它在您机器的每个用户桌面上创建一个文本文件：

	$root = Split-Path $env:USERPROFILE
	
	Resolve-Path $root\*\Desktop |
	  ForEach-Object {
	    $Path = Join-Path -Path $_ -ChildPath 'hello there.txt'
	    'Here is some content...' | Out-File -FilePath $Path
	    Write-Warning "Creating $Path"
	  }

以管理员权限运行您的脚本，它将在您机器中所有用户的桌面上创建一个文件：

	WARNING: Creating C:\Users\Administrator\Desktop\hello there.txt
	WARNING: Creating C:\Users\CustomerService\Desktop\hello there.txt
	WARNING: Creating C:\Users\Guest\Desktop\hello there.txt
	WARNING: Creating C:\Users\PSTestGer\Desktop\hello there.txt
	WARNING: Creating C:\Users\Tester\Desktop\hello there.txt
	WARNING: Creating C:\Users\Tobias\Desktop\hello there.txt

<!--more-->
本文国际来源：[Accessing All Users Desktop](http://community.idera.com/powershell/powertips/b/tips/posts/accessing-all-users-desktop)
