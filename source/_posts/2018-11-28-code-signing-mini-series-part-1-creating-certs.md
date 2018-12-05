---
layout: post
date: 2018-11-28 00:00:00
title: "PowerShell 技能连载 - 代码签名迷你系列（第 1 部分：创建证书）"
description: 'PowerTip of the Day - Code-Signing Mini-Series (Part 1: Creating Certs)'
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
要使用数字签名，以及探索如何对脚本和模块签名，您首先需要代码签名证书。如果您无法从公司的 IT 部门获取到代码签名证书，PowerShell 可以为您创建一个（假设您使用的是 Windows 10 或者 Server 2016）。

我们将这些细节封装为一个名为 `New-CodeSigningCert` 的易用的函数，它可以在个人证书存储中创建新的代码签名证书，并且以 pfx 文件的形式返回新创建的证书。

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
    $cert | Export-PfxCertificate -Password $Password -FilePath $FilePath
    $cert | Remove-Item
    explorer.exe /select,$FilePath
  }
  else { $cert }
}
```

以下是如何以 pfx 文件的形式创建代码签名证书的方法：

```powershell
PS> New-CodeSigningCert -FriendlyName 'Tobias Code-Signing Test Cert' -Name TobiasCS -FilePath "$home\desktop\myCert.pfx" 
```

您将会收到提示，要求输入用来保护 pfx 文件的密码。请记住该密码，一会儿导入 pfx 文件的时候需要该密码。

以下是如何在个人证书存储中创建代码签名证书的方法：

```powershell
PS> New-CodeSigningCert -FriendlyName 'Tobias Code-Signing Test Cert' -Name TobiasCS -Trusted 
```

调用这个函数之后，您的证书现在位于 `cert:` 驱动器中，您现在可以像这样查看它：

```powershell
PS C:\> dir Cert:\CurrentUser\my  
```

同样地，您可以打开个人证书存储来管理它：

```powershell
PS C:\> certmgr.msc
```

请继续关注后续的技能，来学习现在能对代码签名证书做哪些事！

请注意自签名证书仅在复制到受信任的根证书发布者容器之后才能被信任。当使用 `-Trusted` 开关参数之后，会自动应用以上操作。

<!--more-->
本文国际来源：[Code-Signing Mini-Series (Part 1: Creating Certs)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/code-signing-mini-series-part-1-creating-certs)
