---
layout: post
date: 2017-11-02 00:00:00
title: "PowerShell 技能连载 - 对 PowerShell 脚本进行数字签名"
description: PowerTip of the Day - Digitally Signing PowerShell Scripts
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
在前一个技能中您学习了如何创建一个自签名的代码签名证书、将证书保存为一个 PFX 文件，并且将它加载进内存。

今天，假设您已经有了一个包含代码签名证书的 PFX 文件，我们将看看如何对 PowerShell 脚本进行数字签名。

以下代码在您的用户配置文件中查找所有 PowerShell 脚本，如果脚本还未经过数字签名，将会从 PFX 文件中读取一个证书对它进行签名：

```powershell
# read in the certificate from a pre-existing PFX file
$cert = Get-PfxCertificate -FilePath "$env:temp\codeSignCert.pfx"

# find all scripts in your user profile...
Get-ChildItem -Path $home -Filter *.ps1 -Include *.ps1 -Recurse -ErrorAction SilentlyContinue |
# ...that do not have a signature yet...
Where-Object {
    ($_ | Get-AuthenticodeSignature).Status -eq 'NotSigned'
    } |
# and apply one
# (note that we added -WhatIf so no signing occurs. Remove this only if you
# really want to add digital signatures!)
Set-AuthenticodeSignature -Certificate $cert -WhatIf
```

当您在编辑器中查看这些脚本时，您将在脚本的底部看到一个新的注释段。它包含了使用证书加密的脚本的哈希值。他也包含了证书的公开信息。

当您右键点击一个签名的脚本并且选择“属性”，可以看到谁对脚本做了签名。如果您确实信任这个人，您可以将它们的证书安装到受信任的根证书中。

一旦脚本经过数字签名，就可以很方便地审查脚本状态。签名可以告诉您谁签名了一个脚本，以及脚本的内容是否被纂改过。以下代码检查用户配置文件中所有的 PowerShell 脚本并显示签名状态：

```powershell
# find all scripts in your user profile...
Get-ChildItem -Path $home -Filter *.ps1 -Include *.ps1 -Recurse -ErrorAction SilentlyContinue |
# ...and check signature status
Get-AuthenticodeSignature
```

如果您收到“UnknownError”消息，这并不代表是一个未知错误，而是代表脚本未受纂改但签名在系统中是未知的（或非受信的）。

<!--more-->
本文国际来源：[Digitally Signing PowerShell Scripts](http://community.idera.com/powershell/powertips/b/tips/posts/digitally-signing-powershellscripts)
