---
layout: post
title: "PowerShell 技能连载 - 将结果复制到剪贴板"
date: 2013-09-18 00:00:00
description: PowerTip of the Day - Copying Results to Clipboard
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
要将 CmdLet 的输出结果复制到别的应用程序，只需要简单地将它们通过管道传输到 `clip.exe`。然后，将结果粘贴到您所要的应用程序即可：

	Get-Service | clip

<!--more-->
译者注 - CLIP 命令的帮助信息：

	C:\>clip /?
	
	CLIP
	
	描述:
	    将命令行工具的输出重定向到 Windows 剪贴板。这个文本输出可以被粘贴
	    到其他程序中。
	
	参数列表:
	    /?                  显示此帮助消息。
	
	示例:
	    DIR | CLIP          将一份当前目录列表的副本放入 Windows 剪贴板。
	
	    CLIP < README.TXT   将 readme.txt 的一份文本放入 Windows 剪贴板。

<!--more-->

本文国际来源：[Copying Results to Clipboard](http://community.idera.com/powershell/powertips/b/tips/posts/copying-results-to-clipboard)
