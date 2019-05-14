---
layout: post
date: 2019-05-09 00:00:00
title: "PowerShell 技能连载 - 导出和导入代码签名证书"
description: PowerTip of the Day - Exporting and Importing Code-Signing Certificates
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前面的技能里我们解释了如何在 Windows 10 和 Server 2016（以及更高的版本）中创建自签名的代码签名证书。今天，我们来看看如何导出这些证书，创建一个密码保护的文件，然后在不同的机器上再次使用这些证书。

假设您已经在个人证书存储中创建了一个新的代码签名证书，或者在您的证书存储中有一个来自其它来源的代码签名证书。这段代码会将证书导出为一个 PFX 文件放在桌面上：

```powershell
# this password is required to be able to load and use the certificate later
$Password = Read-Host -Prompt 'Enter Password' -AsSecureString
# certificate will be exported to this file
$Path = "$Home\Desktop\myCert.pfx"

# certificate must be in your personal certificate store
$cert = Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert |
          Out-GridView -Title 'Select Certificate' -OutputMode Single
$cert | Export-PfxCertificate -Password $Password -FilePath $Path
```

导出的过程中将会让您输入密码。由于代码签名证书是安全相关的，所以将使用密码来加密存储在 PFX 文件中的证书，并且等等加载证书的时候将需要您输入这个密码。

下一步，将在一个网格视图窗口中显示您个人证书存储中所有的代码签名证书。请选择一个您想导出的证书。

当创建了一个 PFX 文件，您可以用这行命令加载：

```powershell
$cert = Get-PfxCertificate -FilePath $Path
$cert | Select-Object -Property *
```

`Get-PfxCertificate` 将会让您输入创建 PFX 文件时所输入的密码。当证书加载完，您可以执行 `Set-AuthenticodeSignature` 用它来签名文件。

<!--本文国际来源：[Exporting and Importing Code-Signing Certificates](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/exporting-and-importing-code-signing-certificates)-->

