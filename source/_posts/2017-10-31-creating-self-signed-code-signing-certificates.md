---
layout: post
date: 2017-10-31 00:00:00
title: "PowerShell 技能连载 - 创建自签名的代码签名证书"
description: PowerTip of the Day - Creating Self-Signed Code Signing Certificates
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您想对您的脚本进行数字签名，首先您需要一个包含“代码签名”功能的数字证书。如果只是测试，您可以方便地创建免费的个人自签名证书。不要期望其他人信任这些证书，因为任何人都可以创建它们。这是一种很好的测试驱动代码签名的方法。

从 PowerShell 4 开始，`New-SelfSignedCertificate` cmdlet 可以创建签名证书。以下代码创建一个包含私钥和公钥的 PFX 文件：

```powershell
#requires -Version 5

# this is where the cert file will be saved
$Path = "$env:temp\codeSignCert.pfx"

# you'll need this password to load the PFX file later
$Password = Read-Host -Prompt 'Enter new password to protect certificate' -AsSecureString

# create cert, export to file, then delete again
$cert = New-SelfSignedCertificate -KeyUsage DigitalSignature -KeySpec Signature -FriendlyName 'IT Sec Department' -Subject CN=SecurityDepartment -KeyExportPolicy ExportableEncrypted -CertStoreLocation Cert:\CurrentUser\My -NotAfter (Get-Date).AddYears(5) -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.3')
$cert | Export-PfxCertificate -Password $Password -FilePath $Path
$cert | Remove-Item
```

在接下来的技能里，我们将看一看可以用新创建的证书来做什么。

<!--本文国际来源：[Creating Self-Signed Code Signing Certificates](http://community.idera.com/powershell/powertips/b/tips/posts/creating-self-signed-code-signing-certificates)-->
