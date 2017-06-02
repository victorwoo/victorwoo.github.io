---
layout: post
title: "PowerShell 技能连载 - 混淆凭据"
date: 2013-12-10 00:00:00
description: PowerTip of the Day - Obfuscating Credentials
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
您有没有办法安全地将机密的密码包含在 PowerShell 脚本中？您肯定不敢。但您可以使得别人更难以获取到秘密的信息。

以下是一个设计成在 PowerShell ISE 编辑器中使用的代码生成器脚本：

	# ask for credentials
	$cred = Get-Credential
	$pwd = $cred.Password
	$user = $cred.UserName
	
	# create random encryption key
	$key = 1..32 | ForEach-Object { Get-Random -Maximum 256 }
	
	# encrypt password with key
	$pwdencrypted = $pwd | ConvertFrom-SecureString -Key $key
	
	# turn key and password into text representations
	$secret = -join ($key | ForEach-Object { '{0:x2}' -f $_ })
	$secret += $pwdencrypted
	
	# create code
	$code  = '$i = ''{0}'';' -f $secret
	$code += '$cred = New-Object PSCredential('''
	$code += $user + ''', (ConvertTo-SecureString $i.SubString(64)'
	$code += ' -k ($i.SubString(0,64) -split "(?<=\G[0-9a-f]{2})(?=.)" |'
	$code += ' % { [Convert]::ToByte($_,16) })))'
	
	# write new script
	$editor = $psise.CurrentPowerShellTab.files.Add().Editor
	$editor.InsertText($code)
	$editor.SetCaretPosition(1,1)

当您运行它的时候，它将询问用户输入一个用户名和密码。然后，它将会生成一段加密的 PowerShell 脚本片段。您可以在您的脚本中使用它。

以下是由以上脚本生成的一段加密的脚本片段：

	$i = '73cc7284f9e79f68e9d245b5b2d96c4026397d96cfac6023325d1375414e5f7476492d1116743f0423413b16050a5345MgB8AGgAdABLAEkARABiAFIARgBiAGwAZwBHAHMAaQBLAFoAeQB2AGQAOQAyAGcAPQA9AHwAMgBiADIAMABmADYANwA1ADYANwBiAGYAYwA3AGMAOQA0ADIAMQA3ADcAYwAwADUANAA4ADkAZgBhADYAZgBkADkANgA4ADMAZAA5ADUANABjADgAMgAwADQANQA1ADkAZAA3AGUAMwBmADMAMQAzADQAZgBmADIAZABlADgAZQA=';$cred = New-Object PSCredential('contoso\fabrikam', (ConvertTo-SecureString $i.SubString(64) -k ($i.SubString(0,64) -split "(?<=\G[0-9a-f]{2})(?=.)" | % { [Convert]::ToByte($_,16) })))

这段自动生成的加密脚本片段将会定义一个 `$cred` 变量，用于保存包括密码在内的合法凭据。接下来您可以将 `$cred` 变量传递给您脚本中任何需要用户和密码的 `-Credential` 参数。

<!--more-->
本文国际来源：[Obfuscating Credentials](http://community.idera.com/powershell/powertips/b/tips/posts/obfuscating-credentials)
