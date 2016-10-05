layout: post
title: "PowerShell 技能连载 - 获取 DLL 文件版本信息"
date: 2013-12-04 00:00:00
description: PowerTip of the Day - Getting DLL File Version Info
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
是否需要获取一个 DLL 文件列表以及它们的版本信息？`Get-ChildItem` 可以为您获取这些信息。您只需要解开其中的一些属性，例如：

	Get-ChildItem c:\windows\system32\*.dll |
	  Select-Object -ExpandProperty VersionInfo |
	  Select-Object -Property FileName, Productversion, ProductName

以上实际上将原始的 `FileInfo` 对象替换（`-ExpandProperty`）成了 `VersionInfo` 对象。您所做的大概是将一个对象转换成另一个对象，并且丢掉前者的一部分信息。例如，您无法再存取某些属性，如 `LastWriteTime` 等。

如果您希望保持原有的 `FileInfo` 对象，但是为它加入某些额外的信息，那么请像这样使用 `Add-Member`：

	Get-ChildItem c:\windows\system32\*.dll |
	  Add-Member -MemberType ScriptProperty -Name Version -Value {
	  $this.VersionInfo.ProductVersion
	  } -PassThru |
	  Select-Object -Property LastWriteTime, Length, Name, Version |
	  Out-GridView

“$this”是您需要扩展的对象。

<!--more-->
本文国际来源：[Getting DLL File Version Info](http://community.idera.com/powershell/powertips/b/tips/posts/getting-dll-file-version-info)
