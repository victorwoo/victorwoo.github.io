---
layout: post
date: 2018-11-29 00:00:00
title: "PowerShell 技能连载 - 代码签名迷你系列（第 2 部分：从 PFX 文件读取证书）"
description: 'PowerTip of the Day - Code-Signing Mini-Series (Part 2: Reading Certificates from PFX Files)'
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们创建了新的代码签名测试证书，它既是一个 pfx 文件，同时也位于您的证书存储中。今天，我们将看看如何在 PowerShell 中加载这些（或来自其它来源的任意其它证书）。

要从 pfx 文件加载证书，请使用 `Get-PfxCertificate`：

```powershell
$Path = "$home\desktop\tobias.pfx"
$cert = Get-PfxCertificate -FilePath $Path 

$cert | Select-Object -Property *
```

`Get-PfxCertificate` 将提醒输入 pfx 文件创建时输入的密码。有一些 pfx 文件并没有使用密码保护或者是通过您的用户账户来保护证书，这些情况下不会显示提示。

如果您需要自动读取 pfx 证书，以下是一个通过参数输入密码，并且可以无人值守地从 pfx 文件读取证书：

```powershell
function Load-PfxCertificate
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

以下是这个函数工作的方式：

```powershell     
PS C:\> $pwd = 'secret' | ConvertTo-SecureString -AsPlainText -Force
PS C:\> $path = "$home\desktop\tobias.pfx"
PS C:\> $cert = Load-PfxCertificate -FilePath $path -Password $pwd

PS C:\> $cert

Thumbprint                                Subject                              
----------                                -------                              
322CA0B1F37F43B26D4D8DE17DCBF3E2C17CE111  CN=Tobias 
```

修改 `Load-PfxCertificate` 的最后一行，可以支持多于一个证书。改函数永远返回第一个证书 (`$container[0]`)，但是可以选择任意另一个下标。

请关注下一个技能，学习如何存取您个人证书存储中的证书。

<!--本文国际来源：[Code-Signing Mini-Series (Part 2: Reading Certificates from PFX Files)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/code-signing-mini-series-part-2-reading-certificates-from-pfx-files)-->
