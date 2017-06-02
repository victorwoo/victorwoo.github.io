---
layout: post
title: "PowerShell 技能连载 - 密码混淆器脚本"
date: 2013-10-08 00:00:00
description: PowerTip of the Day - Password Obfuscator Script
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
曾经需要将密码保存在脚本中？曾经需要自动弹出一个身份验证对话框？对于前者，将密码和其它身份信息存储在脚本中是很糟糕的；对于后者，如果您这么做了的话，至少能使黑客更难于窃取信息。

以下是一个脚本生成器。运行它，并且输入一个域/用户名和密码，脚本生成器会为您生成一段新脚本。

	$pwd = Read-Host 'Enter Password' 
	$user = Read-Host 'Enter Username'
	$key = 1..32 | 
	  ForEach-Object { Get-Random -Maximum 256 }
	
	$pwdencrypted = $pwd | 
	  ConvertTo-SecureString -AsPlainText -Force | 
	  ConvertFrom-SecureString -Key $key
	
	$text = @()
	$text += '$password = "{0}"' -f ($pwdencrypted -join ' ') 
	$text += '$key = "{0}"' -f ($key -join ' ')
	$text += '$passwordSecure = ConvertTo-SecureString -String $password -Key ([Byte[]]$key.Split(" "))' 
	$text += '$cred = New-Object system.Management.Automation.PSCredential("{0}", $passwordSecure)' -f $user
	$text += '$cred'
	
	$newFile = $psise.CurrentPowerShellTab.Files.Add()
	$newFile.Editor.Text = $text | Out-String

这段脚本包含混淆过的密码脚本，看起来大概类似这样：

	$password = "76492d1116743f0423413b16050a5345MgB8AFcAMABGAEIANAB1AGEAdQA3ADUASABhAE0AMgBNADUAUwBnAFYAYQA1AEEAPQA9AHwAMgAyAGIAZgA1ADUAZgA0ADIANAA0ADUANwA2ADAAMgA5ADkAZAAxAGUANwA4ADUAZQA4ADkAZAA1AGMAMAA2AA=="
	$key = "246 185 95 207 87 105 146 74 99 163 58 194 93 229 80 241 160 35 68 220 130 193 84 113 122 155 208 49 152 86 85 178"
	$passwordSecure = ConvertTo-SecureString -String $password -Key ([Byte[]]$key.Split(" "))
	$cred = New-Object system.Management.Automation.PSCredential("test\tobias", $passwordSecure)
	$cred 

当您运行它，它将生成一个 `Credential` 对象，您可以立即将它用于身份验证。只要将它传给一个需要 `Credential` 对象的形参即可。

再强调一下，这并不是安全的。但是要想获取密码的明文还需要更多点知识才行。

<!--more-->
本文国际来源：[Password Obfuscator Script](http://community.idera.com/powershell/powertips/b/tips/posts/password-obfuscator-script)
