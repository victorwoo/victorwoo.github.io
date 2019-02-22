---
layout: post
title: "PowerShell 技能连载 - 查找所有用户脚本"
date: 2013-10-02 00:00:00
description: PowerTip of the Day - Finding All PowerShell Profile Scripts
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有些时候我们会疑惑当 PowerShell 启动的时候，将执行哪些启动脚本。它们数量很多，而且各不相同，要看您运行的是 PowerShell 控制台，ISE，还是其他宿主。

然而，了解您的用户脚本是十分重要的。它们决定了应用到 PowerShell 环境的配置。

这个 `Get-PSProfileStatus` 函数列出了所有宿主（PowerShell 环境）可能用到的的启动脚本。它也显示了哪些脚本是物理存在的。

	function Get-PSProfileStatus
	{
	    $profile | 
	      Get-Member -MemberType NoteProperty |
	      Select-Object -ExpandProperty Name | 
	      ForEach-Object {
	        $_, (Split-Path $profile.$_ -Leaf), (Split-Path $profile.$_), 
	                              (Test-Path -Path $profile.$_) -join ',' |
	          ConvertFrom-Csv -Header Profile, FileName, FolderName, Present
	        }
	}
	
	Get-PSProfileStatus

结果看起来类似这样：

![](/img/2013-10-02-finding-all-powershell-profile-scripts-001.png)

将结果用管道输出到 `Out-GridView` 来查看，避免截断字符被截断：

	Get-PSProfileStatus | Out-GridView


<!--本文国际来源：[Finding All PowerShell Profile Scripts](http://community.idera.com/powershell/powertips/b/tips/posts/finding-all-powershell-profile-scripts)-->
