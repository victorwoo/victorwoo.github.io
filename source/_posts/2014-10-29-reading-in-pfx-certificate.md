---
layout: post
date: 2014-10-29 11:00:00
title: "PowerShell 技能连载 - 读取 PFX 证书"
description: PowerTip of the Day - Reading In PFX-Certificate
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell 所有版本_

当您使用 `Get-PfxCertificate` 命令时，您可以读取 PFX 证书文件，并使用证书来为脚本签名。然而，该命令总是交互式地询问证书的密码。

以下这段代码可以通过脚本来提交密码：

    $PathToPfxFile = 'C:\temp\test.pfx'
    $PFXPassword = 'test'
    
    Add-Type -AssemblyName System.Security
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    $cert.Import($PathToPfxFile, $PFXPassword, 'Exportable')
    
    $cert

<!--本文国际来源：[Reading In PFX-Certificate](http://community.idera.com/powershell/powertips/b/tips/posts/reading-in-pfx-certificate)-->
