layout: post
title: "PowerShell 技能连载 - 解锁下载的文件"
date: 2014-01-22 00:00:00
description: PowerTip of the Day - Unblocking Download Files
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
任何从 Internet 下载的以及从邮件接收到的文件，都被 Windows 隐式地标记为不安全的。如果文件包含可执行文件或二进制文件，它们必须解锁以后才可以运行。

PowerShell 3.0 以及以上的版本可以检测到包含“下载标记”的文件：

	Get-ChildItem -Path $Home\Downloads -Recurse |
	  Get-Item -Stream Zone.Identifier -ErrorAction Ignore |
	  Select-Object -ExpandProperty FileName |
	  Get-Item

这段代码或许不会返回任何文件（当没有文件具有下载标记的情况下），或许会返回一大堆文件（这也许意味着您解压了一个下载的 ZIP 文件，但忘了先对它解锁）。

要解锁这些文件，请使用 `Unblock-File` cmdlet。这段代码将解锁您下载文件夹中当前被锁定的文件（不涉及到其它任何文件）：

	Get-ChildItem -Path $Home\Downloads -Recurse |
	  Get-Item -Stream Zone.Identifier -ErrorAction Ignore |
	  Select-Object -ExpandProperty FileName |
	  Get-Item |
	  Unblock-File

<!--more-->
本文国际来源：[Unblocking Download Files](http://community.idera.com/powershell/powertips/b/tips/posts/unblocking-download-files)
