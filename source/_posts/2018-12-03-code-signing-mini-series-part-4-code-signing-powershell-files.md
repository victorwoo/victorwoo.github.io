---
layout: post
date: 2018-12-03 00:00:00
title: "PowerShell 技能连载 - 代码签名迷你系列（第 4 部分：签名 PowerShell 文件）"
description: 'PowerTip of the Day - Code-Signing Mini-Series (Part 4: Code-Signing PowerShell Files)'
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在将 PowerShell 脚本发送给别人之前，最好对它进行数字签名。签名的角色类似脚本的“包装器”，可以帮助别人确认是谁编写了这个脚本以及这个脚本是否仍是原始本版本，或是已被篡改过。

要对 PowerShell 脚本签名，您需要一个数字代码签名证书。在前一个技能中我们解释了如何创建一个该证书，并且/或者从 pfx 或证书存储中加载该证书。以下代码假设在 `$cert` 中已经有了一个合法的代码签名证书。如果还没有，请先阅读之前的技能文章！

```powershell
# make sure this PFX file exists or create one
# or load a code-signing cert from other sources
# (review the previous tips for hints)
$pfxFile = "$home\desktop\tobias.pfx"
$cert = Get-PfxCertificate -FilePath $pfxFile

# make sure this folder exists and contains
# PowerShell script that you'd like to sign
$PathWithScripts = 'c:\myScripts'

# apply signatures to all scripts in the folder
Get-ChildItem -Path $PathWithScripts -Filter *.ps1 -Recurse |
  Set-AuthenticodeSignature -Certificate $cert
```

运行这段代码后，指定目录中的所有脚本都会添加上数字签名。如果您连接到了 Internet，应该考虑签名时使用时间戳服务器，并且将最后一行代码替换成这行：

```powershell
# apply signatures to all scripts in the folder
Get-ChildItem -Path $PathWithScripts -Filter *.ps1 -Recurse |
  Set-AuthenticodeSignature -Certificate $cert -TimestampServer http://timestamp.digicert.com  
```

使用时间戳服务器会减慢签名的速度但是确保不会用过期的证书签名：例如当某天一本证书过期了，但是签名仍然有效。因为官方的时间戳服务器，签名仍然有效，因为官方的时间戳服务器证明该签名是在证书过期之前应用的。

<!--本文国际来源：[Code-Signing Mini-Series (Part 4: Code-Signing PowerShell Files)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/code-signing-mini-series-part-4-code-signing-powershell-files)-->
