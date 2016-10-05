layout: post
title: "PowerShell 技能连载 - 创建符号链接"
date: 2013-09-25 00:00:00
description: PowerTip of the Day - Creating Symbolic Links
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
符号链接使用起来很像“普通”的链接文件（\*.lnk）：它们可以虚拟地指向任何文件或者文件夹，甚至UNC路径。和lnk文件不同的是，创建符号链接需要完整管理员权限，并且用户不可以存取符号链接属性。

以下是一个创建符号链接的函数：
<!--more-->

	function New-SymbolicLink
	{
	    param
	    (
	        [Parameter(Mandatory=$true)]
	        $OriginalPath,
	
	        [Parameter(Mandatory=$true)]
	        $MirroredPath,
	
	        [ValidateSet('File', 'Directory')]
	        $Type='File'
	    )
	    
	    if(!([bool]((whoami /groups) -match "S-1-16-12288") ))
	    {
	        Write-Warning 'Must be an admin'
	        break
	    }
	    $signature = '
	        [DllImport("kernel32.dll")]
	        public static extern bool CreateSymbolicLink(string lpSymlinkFileName, string lpTargetFileName, int dwFlags);
	        '
	    Add-Type -MemberDefinition $signature -Name Creator -Namespace SymbolicLink 
	
	    $Flags = [Int]($Type -eq 'Directory')
	    [SymbolicLink.Creator]::CreateSymbolicLink($MirroredPath, $OriginalPath,$Flags)
	}
	
	$downloads = "$env:userprofile\Downloads"
	$desktop = "$env:userprofile\Desktop\MyDownloads"
	
	New-SymbolicLink -OriginalPath $downloads -MirroredPath $desktop -Type Directory

当您（以管理员身份）运行这段代码时，它将使您能在桌面上访问下载文件夹。请右击符号链接并选择**属性**，并和“普通”的\*.link文件做对比。
<!--more-->

本文国际来源：[Creating Symbolic Links](http://community.idera.com/powershell/powertips/b/tips/posts/creating-symbolic-links)
