---
layout: post
date: 2022-11-02 00:00:00
title: "PowerShell 技能连载 - 创建新的代码签名测试证书"
description: PowerTip of the Day - Creating New Code Signing Test Certificates
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 配备了一个名为 `New-SelfSignedCertificate` 的 cmdlet，可以创建各种自签名的测试证书。但是，使用它为 PowerShell 代码签名创建证书并不直观，更不用说在测试机上确保测试证书值得信任。

所以我们编写了一个函数将上述 cmdlet 包装起来，使得创建既持久且可导出的代码签名证书变得更加容易：

```powershell
function New-CodeSigningCert
{
  [CmdletBinding(DefaultParametersetName="__AllParameterSets")]
  param
  (
    [Parameter(Mandatory)]
    [String]
    $FriendlyName,

    [Parameter(Mandatory)]
    [String]
    $Name,

    [Parameter(Mandatory,ParameterSetName="Export")]
    [SecureString]
    $Password,

    [Parameter(Mandatory,ParameterSetName="Export")]
    [String]
    $FilePath,

    [Switch]
    $Trusted
  )

  # create new cert
  $cert = New-SelfSignedCertificate -KeyUsage DigitalSignature -KeySpec Signature -FriendlyName $FriendlyName -Subject "CN=$Name" -KeyExportPolicy ExportableEncrypted -CertStoreLocation Cert:\CurrentUser\My -NotAfter (Get-Date).AddYears(5) -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.3')


  if ($Trusted)
  {
    $Store = New-Object system.security.cryptography.X509Certificates.x509Store("Root", "CurrentUser")
    $Store.Open("ReadWrite")
    $Store.Add($cert)
    $Store.Close()
  }


  $parameterSet = $PSCmdlet.ParameterSetName.ToLower()

  if ($parameterSet -eq "export")
  {
    # export to file
    $cert | Export-PfxCertificate -Password $Password -FilePath $FilePath

    $cert | Remove-Item
    explorer.exe /select,$FilePath
  }
  else
  {
    $cert
  }
}
```

<!--本文国际来源：[Creating New Code Signing Test Certificates](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/creating-new-code-signing-test-certificates)-->

