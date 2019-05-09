---
layout: post
date: 2019-05-08 00:00:00
title: "PowerShell 技能连载 - 创建代码签名证书"
description: PowerTip of the Day - Creating Code-Signing Certificates
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Windows 10 和 Serve 2016（以及更高版本）带有一个高级的 `New-SelfSignedCert` cmdlet，它可以用来创建代码签名证书。通过代码签名证书，您可以对 PowerShell 脚本进行数字签名并使用这个签名来检测用户是否改篡改过脚本内容。

以下是一个用来创建代码签名证书的函数：

```powershell
function New-CodeSigningCert
{
    param
    (
        [Parameter(Mandatory, Position=0)]
        [System.String]
        $FriendlyName,

        [Parameter(Mandatory, Position=1)]
        [System.String]
        $Name
    )

    # Create a certificate:
    New-SelfSignedCertificate -KeyUsage DigitalSignature -KeySpec Signature -FriendlyName $FriendlyName -Subject "CN=$Name" -KeyExportPolicy ExportableEncrypted -CertStoreLocation Cert:\CurrentUser\My -NotAfter (Get-Date).AddYears(5) -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.3')
}
```

要创建一个新的证书，请运行这行代码：

```powershell
PS> New-CodeSigningCert -FriendlyName TobiasWeltner -Name TWeltner


   PSParentPath: Microsoft.PowerShell.Security\Certificate::CurrentUser\My

Thumbprint                                Subject
----------                                -------
2350D77A4CACAF17136B94D297DEB1A5E413655D  CN=TWeltner
```

使用新的代码签名证书，您可以对脚本进行数字签名。代码签名证书位于个人证书存储中。要使用它，需要先从存储中读取它：

```powershell
$cert = Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert |
          Out-GridView -Title 'Select Certificate' -OutputMode Single
```

要签名一个单独的脚本，请使用这行代码：

```powershell
$Path = "C:\path\to\your\script.ps1"

Set-AuthenticodeSignature -Certificate $cert -FilePath $Path
```

如果您希望通过时间戳签名，请使用这行代码：

```powershell
Set-AuthenticodeSignature -Certificate $cert -TimestampServer http://timestamp.digicert.com -FilePath $Path
```

当签名使用的证书过期以后，时间戳签名仍然有效。

要批量签名多个脚本，请使用 `Get-ChildItem` 并用管道将文件传送到 `Set-AuthenticodeSignature`。这行代码将对用户配置文件中的所有 PowerShell 脚本签名：

```powershell
Get-ChildItem -Path "$home\Documents" -Filter *.ps1 -Include *.ps1 -Recurse |
Set-AuthenticodeSignature -Certificate $cert
```

当您得到了签名后的脚本，随时可以使用 `Get-AuthenticodeSignature` 来检查签名的完整性：

```powershell
Get-ChildItem -Path "$home\Documents" -Filter *.ps1 -Include *.ps1 -Recurse |
Get-AuthenticodeSignature
```

<!--本文国际来源：[Creating Code-Signing Certificates](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/creating-code-signing-certificates)-->

