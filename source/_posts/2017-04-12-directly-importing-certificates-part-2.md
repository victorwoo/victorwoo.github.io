---
layout: post
date: 2017-04-12 00:00:00
title: "PowerShell 技能连载 - 直接导入证书（第二部分）"
description: PowerTip of the Day - Directly Importing Certificates (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们演示了如何在任何版本的 PowerShell 中用 .NET 方法导入数字证书。新版本的 PowerShell 有一个 "PKI" module，其中包括了 `Import-Certificate` cmdlet，导入证书变得更简单了。

```powershell
#requires -Version 2.0 -Modules PKI 
# importing to personal store
$Path = 'C:\Path\To\CertFile.cer'
Import-Certificate -FilePath $Path -CertStoreLocation Cert:\CurrentUser\My
```

请注意 `Import-Certificate` 如何通过 `-CertStoreLocation` 指定目标存储位置。这个命令返回导入的证书。

<!--本文国际来源：[Directly Importing Certificates (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/directly-importing-certificates-part-2)-->
