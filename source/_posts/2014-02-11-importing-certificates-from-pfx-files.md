layout: post
title: "PowerShell 技能连载 - 从 PFX 文件中导入证书"
date: 2014-02-11 00:00:00
description: PowerTip of the Day - Importing Certificates from PFX Files
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
您可以使用 `Get-PfxCertificate` 来从 PFX 文件中读取数字证书，然后用数字证书来为脚本文件签名，例如：

	$pfxpath = 'C:\PathToPfxFile\testcert.pfx'
	$cert = Get-PfxCertificate -FilePath $pfxpath
	$cert

	Get-ChildItem -Path c:\myscripts -Filter *.ps1 | Set-AuthenticodeSignature -Certificate $cert

然而，`Get-PfxCertificate` 将会交互式地询问您导出证书至 PFX 文件时所用的密码：

要静默地导入证书，请使用这段代码：

	$pfxpath = 'C:\PathToPfxFile\testcert.pfx'
	$password = 'topsecret'
	
	Add-Type -AssemblyName System.Security
	$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
	$cert.Import($pfxpath, $password, 'Exportable')
	$cert

<!--more-->
本文国际来源：[Importing Certificates from PFX Files](http://community.idera.com/powershell/powertips/b/tips/posts/importing-certificates-from-pfx-files)
