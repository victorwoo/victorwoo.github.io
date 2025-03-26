---
layout: post
date: 2022-05-24 00:00:00
title: "PowerShell 技能连载 - 签名 PowerShell 脚本（第 3 部分）"
description: PowerTip of the Day - Code-Signing PowerShell Scripts (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一部分中，我们创建了一个代码签名证书，并将其用于将数字签名添加到 PowerShell 脚本文件中。 然而，将数字签名添加到 PowerShell 脚本文件中可以做什么？

使用 `Get-AuthenticodeSignature` 可以查看数字签名中的秘密。只需确保您调整 `$Path` 以指向具有数字签名的文件：

```powershell
# path to a digitally signed file (adjust path to an existing signed ps1 file):
$Path = "$env:temp\test.ps1"
$Status = Get-AuthenticodeSignature -FilePath $Path | Select-Object -Property *
$Status
```

结果类似这样：

    SignerCertificate      : [Subject]
                               CN=MyPowerShellCode

                             [Issuer]
                               CN=MyPowerShellCode

                             [Serial Number]
                               1B98E986A1D7BCB245034A0225381CA4

                             [Not Before]
                               01.05.2022 17:39:56

                             [Not After]
                               01.05.2027 17:49:56

                             [Thumbprint]
                               F4C1F9978D564E143D554F3679746B3A79E1FF87

    TimeStamperCertificate :
    Status                 : UnknownError
    StatusMessage          : A certificate chain processed, but terminated in a root certificate which is not trusted by the trust provider
    Path                   : C:\Users\tobia\AppData\Local\Temp\test.ps1
    SignatureType          : Authenticode
    IsOSBinary             : False

最重要的返回属性是 "Status"（及其在 "StatusMessage" 中找到的友好信息）。该属性告诉您签名的文件外的印章是否值得信赖和未被篡改：

| Status 	| Description 	|
|---	|---	|
| UnknownError 	| 文件未被篡改，但是签名用的数字证书可能不受信任 	|
| HashMismatch 	| 自上次签名依赖，文件内容已改变 	|
| Valid 	| 文件未被篡改，且数字证书受信任 	|
| NotSigned 	| 文件未携带数字证书 	|

最有可能的是，您会看到状态 "UnknownError"（如果您添加签名以来文件内容没有更改）或 "HashMismatch"（您或其他人确实更改了文件）。

您可能看不到 "Valid" 的原因是我们在此迷你系列中使用的证书类型：任何人都可以创建一个自签名的证书，以便攻击者可以更改脚本文件，然后使用他拥有自签名的证书以重新签名文件。

由于每个证书——公司或自签名——始终都有其独特的指纹，因此即使是对于自签名证书，您也可以通过同时检查 "Status" 和 "SignerCertificate.Thumbprint"，来确认脚本的完整性。当您还检查证书指纹时，邪恶的人就无法在不更改指纹的情况下重新签名脚本：

```powershell
# thumbprint of your certificate (adjust to match yours)
$thumbprint = 'F4C1F9978D564E143D554F3679746B3A79E1FF87'

# path to a digitally signed file (adjust path to an existing signed ps1 file):
$Path = "$env:temp\test.ps1"
$Status = Get-AuthenticodeSignature -FilePath $Path | Select-Object -Property *
$ok = $Status.Status -eq 'Valid' -or ($status.Status -eq 'UnknownError' -and $status.SignerCertificate.Thumbprint -eq $thumbprint)
"Script ok: $ok"
```

<!--本文国际来源：[Code-Signing PowerShell Scripts (Part 3)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/code-signing-powershell-scripts-part-3)-->

