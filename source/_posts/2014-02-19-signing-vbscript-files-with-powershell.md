layout: post
title: "PowerShell 技能连载 - 用 PowerShell 为 VBScript 文件签名"
date: 2014-02-19 00:00:00
description: PowerTip of the Day - Signing VBScript Files with PowerShell
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
您很可能知道 `Set-AuthenticodeSignature` 可以用来为 PowerShell 脚本签名。但您是否知道这个 cmdlet 可以为任何支持目标接口包 (SIP) 的任何文件呢？

这段代码可以从一个 PFX 文件中读取数字证书，然后从您的 home 文件夹中扫描 VBScript 文件，然后将数字签名应用到脚本文件上：

    # change path to point to your PFX file:
    $pfxpath = 'C:\Users\Tobias\Documents\PowerShell\testcert.pfx'
    # change password to the password needed to read the PFX file:
    # (this password was set when you exported the certificate to a PFX file)
    $password = 'topsecret'
    
    # load certificate
    Add-Type -AssemblyName System.Security
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    $cert.Import($pfxpath, $password, 'Exportable')
    
    # apply signature to all VBScript files
    # REMOVE -WHATIF TO ACTUALLY SIGN
    Get-ChildItem -Path $home -Filter *.vbs -Recurse -ErrorAction SilentlyContinue |
      Set-AuthenticodeSignature -Certificate $cert -WhatIf

<!--more-->
本文国际来源：[Signing VBScript Files with PowerShell](http://community.idera.com/powershell/powertips/b/tips/posts/signing-vbscript-files-with-powershell)
