---
layout: post
date: 2018-04-05 00:00:00
title: "PowerShell 技能连载 - 检查数字签名"
description: PowerTip of the Day - Examining Digital Signature Signers
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您从 internet 下载一个脚本时，它可能包含了一个数字签名，数字签名能帮您确定脚本是从哪里来的。我们在前一个技能里讨论了这个内容，以下是我们使用的代码：它将一个 PowerShell 脚本下载到磁盘，然后显示它的数字签名：

```powershell
# save script to file
$url = 'https://chocolatey.org/install.ps1'
$outPath = "$env:temp\installChocolatey.ps1"
Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $outPath

# test signature
Get-AuthenticodeSignature -FilePath $outPath
```

结果类似这样：

        Directory: C:\Users\tobwe\AppData\Local\Temp
    
    
    SignerCertificate                         Status         Path                       
    -----------------                         ------         ----                       
    493018BA27EAA09B895BC5660E77F694B84877C7  Valid          installChocolatey.ps1

"Status" 列报告了这个文件是否可信。然而如何获取更多的关于证书和它的所有者的信息，特别是找出 "493018BA27EAA09B895BC5660E77F694B84877C7" 是谁？

只需要将签名证书传给一个 Windows API 函数，就可以显示证书的属性对话框：

```powershell
# save script to file
$url = 'https://chocolatey.org/install.ps1'
$outPath = "$env:temp\installChocolatey.ps1"
Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $outPath

# test signature
$result = Get-AuthenticodeSignature -FilePath $outPath
$signerCert = $result.SignerCertificate

Add-Type -Assembly System.Security
[Security.Cryptography.x509Certificates.X509Certificate2UI]::DisplayCertificate($signerCert)
```

现在您能了解到该证书编号指向 "Chocolatey Software, Inc" 公司，以及该证书是由 DigiCert 颁发。这是为什么 Windows 信任该签名：DigiCert 采取措施验证签名人的个人详细信息。

<!--本文国际来源：[Examining Digital Signature Signers](http://community.idera.com/powershell/powertips/b/tips/posts/examining-digital-signature-signers)-->
