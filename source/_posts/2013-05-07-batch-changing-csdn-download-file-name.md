---
layout: post
title: "批量更改csdn下载的文件名（UrlDecode) "
date: 2013-05-07 00:00:00
description: batch changing csdn download file name
categories: powershell
tags:
- powershell
- script
- batch
- download
---
例如csdn下载的一个文件名字为 `%5B大家网%5DWindows.PowerShell应用手册%5Bwww.TopSage.com%5D.pdf`，我们通过两行PowerShell脚本把它转化为正常的 `[大家网]Windows.PowerShell应用手册[www.TopSage.com].pdf`。量大的时候特别好用。

方法如下：

	Add-Type -AssemblyName System.Web
	dir | % { ren -LiteralPath $_ ([System.Web.HttpUtility]::UrlDecode($_)) }
