---
layout: post
date: 2022-11-04 00:00:00
title: "PowerShell 技能连载 - 无人值守读取 PFX 证书"
description: PowerTip of the Day - Loading PFX Certificate Unattendedly
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 配备了一个名为 `Get-PfxCertificate` 的 cmdlet，您可以用来将证书和私钥加载到内存中。但是如果证书受密码保护，则有一个强制性提示来输入密码。您不能通过参数提交密码，因此该 cmdlet 不能无人值守使用。

这是一个替代的函数，允许通过参数输入密码，从而允许以无人值守的方式即时加载 pfx 证书：

```powershell
function Get-PfxCertificateUnattended
{
  param
  (
    [String]
    [Parameter(Mandatory)]
    $FilePath,

    [SecureString]
    [Parameter(Mandatory)]
    $Password
  )

  # get clear text password
  $plaintextPassword = [PSCredential]::new("X", $Password).GetNetworkCredential().Password


  [void][System.Reflection.Assembly]::LoadWithPartialName("System.Security")
  $container = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection
  $container.Import($FilePath, $plaintextPassword, 'PersistKeySet')
  $container[0]
}
```

请注意，该功能始终返回 pfx 文件中发现的第一个证书 如果您的PFX文件包含多个证书，则可能需要在最后一行代码中调整索引。

<!--本文国际来源：[Loading PFX Certificate Unattendedly](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/loading-pfx-certificate-unattendedly)-->

