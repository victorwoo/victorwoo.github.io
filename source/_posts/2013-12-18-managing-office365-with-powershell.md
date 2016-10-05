layout: post
title: "PowerShell 技能连载 - 使用 PowerShell 管理 Office365"
date: 2013-12-18 00:00:00
description: PowerTip of the Day - Managing Office365 with PowerShell
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
您知道吗？您也可以用 PowerShell 管理您的 Office365 账户。如果您拥有一个 Office365 账户，请试试以下脚本：

	$OfficeSession = New-PSSession -ConfigurationName Microsoft.Exchange `-ConnectionUri https://ps.outlook.com/powershell/ -Credential (Get-Credential) `-Authentication Basic -AllowRedirection
	
	$import = Import-PSSession $OfficeSession -Prefix Off365
	
	Get-Command -Noun Off365*

这段代码将使用您的凭据连接 Office 365，然后导入用于管理 Office 365 的 PowerShell cmdlet。您大约可以获得 400 个新的 cmdlet。如果您收到“Access Denied”提示，那么有可能您的账户没有足够的权限，或者您敲错了密码。 

注意所有导入的 cmdlet 都是以 `Off365` 为前缀的，所以要查看所有的邮箱，请试试以下代码：

	PS> Get-Off365Mailbox

您可以自己选择前缀（见前面的代码），这样您可以同时通过不同的前缀连接到多个 Office365 账户。当您执行 `Import-PSSession` 时，您还可以省略前缀。

要查看 Office365 导出的所有命令，请使用以下代码：

	$import.ExportedCommands

<!--more-->
本文国际来源：[Managing Office365 with PowerShell](http://community.idera.com/powershell/powertips/b/tips/posts/managing-office365-with-powershell)
