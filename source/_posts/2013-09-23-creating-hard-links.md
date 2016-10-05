layout: post
title: "PowerShell 技能连载 - 创建硬连接"
date: 2013-09-23 00:00:00
description: PowerTip of the Day - Creating Hard Links
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
硬连接是NTFS文件系统中文件的“镜像”。它们使得一个文件能在多个文件系统位置（必须在一个卷中）中出现。

所以文件仅仅占用它的原始位置空间，但是在其它地方也可用。当您需要让大文件在多个地方可用的时候，这是一个十分有用的功能。

以下是 `New-HardLink` 函数的介绍。它演示了PowerShell如何调用底层的API函数：
<!--more-->

	function New-HardLink
	{
	    param
	    (
	        [Parameter(Mandatory=$true)]
	        $OriginalFilePath,
	
	        [Parameter(Mandatory=$true)]
	        $MirroredFilePath
	    )
	
	    $signature = '
	            [DllImport("Kernel32.dll")]
	            public static extern bool CreateHardLink(string lpFileName,string lpExistingFileName,IntPtr lpSecurityAttributes);
	    '
	    Add-Type -MemberDefinition $signature -Name Creator -Namespace Link 
	
	    [Link.Creator]::CreateHardLink($MirroredFilePath,$OriginalFilePath,[IntPtr]::Zero)
	
	} 

以下是它的使用方法：

	$Original = "$env:temp\testfile.txt"
	$Copy1 = "$env:userprofile\Desktop\mirrorfile1.txt"
	$Copy2 = "$env:userprofile\Desktop\mirrorfile2.txt"
	
	# create original file:
	Set-Content -Path $Original -Value 'Hello'
	
	# create hard link #1:
	New-HardLink -OriginalFilePath $Original -MirroredFilePath $Copy1
	
	# create hard link #2:
	New-HardLink -OriginalFilePath $Original -MirroredFilePath $Copy2 

这段代码首先在临时文件夹中创建一个物理文件。然后在您的桌面上创建两个硬连接。它们看上去分别是*mirrorfile1.txt*和*mirrorfile2.txt*。虽然它们看上去像是独立的文件，而实际上他们都指向刚创建的临时文件。 

您可以打开桌面上两个文件中的某一个，做一些修改，然后保存并关闭。当打开另一个文件时，您可以看到一模一样的修改后的内容。您还可以简单地删掉一个镜像文件来移除硬连接。
<!--more-->

本文国际来源：[Returning Multiple Values](http://community.idera.com/powershell/powertips/b/tips/posts/returning-multiple-values)
