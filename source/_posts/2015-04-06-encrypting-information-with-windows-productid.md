layout: post
date: 2015-04-06 11:00:00
title: "PowerShell 技能连载 - 用 Windows 加密信息"
description: PowerTip of the Day - Encrypting Information with Windows ProductID
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

要存储机密信息，您可以使用 `SecureString` 对象将其保存到磁盘上。PowerShell 自动使用用户账户作为密钥，所以只有保存该信息的用户可以读取它。

如果您希望该机密信息不绑定到特定的用户，而是绑定到某台机器，您可以使用 Windows 产品序列号作为密钥。请注意这并不是特别安全，因为密钥在 Windows 注册表中时公开可见的。它还有个使用前提是 Windows 是使用合法产品序列号安装的。

以下这段代码接受任意文本信息，然后用 Windows 产品序列号对它进行加密并保存到磁盘上：

    $Path = "$env:temp\secret.txt"
    $Secret = 'Hello World!'
    
    $regKey = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name DigitalProductID
    $encryptionKey = $regKey.DigitalProductID
    
    $Secret |
      ConvertTo-SecureString -AsPlainText -Force | 
      ConvertFrom-SecureString -Key ($encryptionKey[0..23]) | 
      Out-File -FilePath $Path
    
    notepad $Path

这是对加密的文本进行解密的代码：

    $Path = "$env:temp\secret.txt"
    
    $regKey = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name DigitalProductID
    $encryptionKey = $regKey.DigitalProductID
    
    $decryptedTextSecureString = Get-Content -Path $Path -Raw |
      ConvertTo-SecureString -Key ($secureKey[0..23])
    
    $cred = New-Object -TypeName System.Management.Automation.PSCredential('dummy', $decryptedTextSecureString)
    $decryptedText = $cred.GetNetworkCredential().Password
    
    "The decrypted secret text: $decryptedText"

请注意如何 `PSCredential` 对象来对密文进行解密并还原出明文的。

<!--more-->
本文国际来源：[Encrypting Information with Windows ProductID](http://community.idera.com/powershell/powertips/b/tips/posts/encrypting-information-with-windows-productid)
