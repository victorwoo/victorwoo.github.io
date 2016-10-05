layout: post
title: "PowerShell 技能连载 - 从 PFX 文件中导入多个证书"
date: 2014-02-14 00:00:00
description: PowerTip of the Day - Importing Multiple Certificates from PFX Files
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
`Get-PfxCertificate` 可以从 PFX 文件中导入数字证书。然而，他只能获取一个证书。所以如果您的 PFX 文件中包含多个证书，您无法使用这个 cmdlet 获取其它的证书。

若要从一个 PFX 文件中导入多个证书，只要使用以下代码：

	$pfxpath = 'C:\PathToPfxFile\testcert.pfx'
	$password = 'topsecret'
	
	Add-Type -AssemblyName System.Security
	$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection
	$cert.Import($pfxpath, $password, 'Exportable')
	$cert

<!--more-->
本文国际来源：[Importing Multiple Certificates from PFX Files](http://community.idera.com/powershell/powertips/b/tips/posts/importing-multiple-certificates-from-pfx-files)
