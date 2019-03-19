---
layout: post
date: 2017-03-31 00:00:00
title: "PowerShell 技能连载 - 检查证书详细信息"
description: PowerTip of the Day - Examining Certificate Details
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您想检查和查看一个证书文件的详细信息而不需要将它导入证书存储空间，以下是一个简单的例子：

```powershell
# replace path with actual path to CER file
$Path = 'C:\Path\To\CertificateFile\test.cer'

Add-Type -AssemblyName System.Security
[Security.Cryptography.X509Certificates.X509Certificate2]$cert = [Security.Cryptography.X509Certificates.X509Certificate2]::CreateFromCertFile($Path)

$cert | Select-Object -Property *
```

您现在可以存取所有详细信息并获取指纹或检查失效日期：

```powershell
PS C:\> $cert.Thumbprint
7A5A350D95247BB173CDF0867ADA2DBFFCCABDE6

PS C:\> $cert.NotAfter

Monday June 12 2017 06:00:00
```

<!--本文国际来源：[Examining Certificate Details](http://community.idera.com/powershell/powertips/b/tips/posts/examining-certificate-details)-->
