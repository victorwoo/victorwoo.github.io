---
layout: post
date: 2015-04-07 11:00:00
title: "PowerShell 技能连载 - 用口令对文本信息加密"
description: PowerTip of the Day - Encrypting Text Information Using Passphrase
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
_适用于 PowerShell 3.0 及以上版本_

在前一个技能中，我们介绍了如何使用 Windows 注册表中的 Windows 产品序列号来加密文本信息。

如果您觉得这种方式不够安全，那么可以使用自己指定的密钥来加密。以下例子演示了如何使用密码作为加密密钥：

    $Path = "$env:temp\secret.txt"
    $Secret = 'Hello World!'
    $Passphrase = 'Some secret key'
    
    $key = [Byte[]]($Passphrase.PadRight(24).Substring(0,24).ToCharArray())
    
    $Secret |
      ConvertTo-SecureString -AsPlainText -Force | 
      ConvertFrom-SecureString -Key $key | 
      Out-File -FilePath $Path
    
    notepad $Path

要解密一段密文，您需要知道对应的密码：

    $Passphrase = Read-Host 'Enter the secret pass phrase'
    
    $Path = "$env:temp\secret.txt"
    
    $key = [Byte[]]($Passphrase.PadRight(24).Substring(0,24).ToCharArray())
    
    try
    {
      $decryptedTextSecureString = Get-Content -Path $Path -Raw |
      ConvertTo-SecureString -Key $key -ErrorAction Stop
    
      $cred = New-Object -TypeName System.Management.Automation.PSCredential('dummy', $decryptedTextSecureString)
      $decryptedText = $cred.GetNetworkCredential().Password
    }
    catch
    {
      $decryptedText = '(wrong key)'
    }
    "The decrypted secret text: $decryptedText"

<!--more-->
本文国际来源：[Encrypting Text Information Using Passphrase](http://community.idera.com/powershell/powertips/b/tips/posts/encrypting-text-information-using-passphrase)
