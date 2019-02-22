---
layout: post
title: "PowerShell 技能连载 - 读写 NTFS 流"
date: 2014-01-27 00:00:00
description: PowerTip of the Day - Reading and Writing NTFS Streams
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当一个文件存储在 NTFS 文件系统分区时，您可以向它附加数据流来存储隐藏信息。

以下是一个将 PowerShell 代码隐藏在 NTFS 流中的例子。当您运行这段代码时，它将在您的桌面上创建一个新的 PowerShell 脚本文件，然后在 ISE 编辑器中打开这个文件：

	$path = "$home\Desktop\secret.ps1"
	
	$secretCode = {
	  Write-Host -ForegroundColor Red 'This is a miracle!';
	  [System.Console]::Beep(4000,1000)
	}
	
	Set-Content -Path $path -Value '(Invoke-Expression ''[ScriptBlock]::Create((Get-Content ($MyInvocation.MyCommand.Definition) -Stream SecretStream))'').Invoke()'
	Set-Content -Path $path -Stream SecretStream -Value $secretCode
	ise $path

这个新的文件将看上去只是包含以下代码：

	(Invoke-Expression '[ScriptBlock]::Create((Get-Content ($MyInvocation.MyCommand.Definition) -Stream SecretStream))').Invoke()

而当您运行这个脚本文件时，它将显示一段红色的文本并且蜂鸣一秒钟。所以新创建的脚本实际上执行了嵌入在隐藏 NTFS 流中名为“SecretStream”的代码。

要向 NTFS 卷中的（任何）文件附加隐藏信息，请使用 `Add-Content` 或 `Set-Content` 命令以及 `-Stream` 参数。

要从一个流中读取隐藏信息，请使用 `Get-Content` 命令，并为 `-Stream` 参数指定存储数据时用的名字。

<!--本文国际来源：[Reading and Writing NTFS Streams](http://community.idera.com/powershell/powertips/b/tips/posts/reading-and-writing-ntfs-streams)-->
