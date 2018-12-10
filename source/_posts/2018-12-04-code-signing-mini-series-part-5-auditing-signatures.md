---
layout: post
date: 2018-12-04 00:00:00
title: "PowerShell 技能连载 - 代码签名迷你系列（第 5 部分：审计签名）"
description: 'PowerTip of the Day - Code-Signing Mini-Series (Part 5: Auditing Signatures)'
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
当 Powershell 脚本携带一个数字签名后，您可以快速地找出是谁对这个脚本签的名，更重要的是，这个脚本是否未被篡改。在本系列之前的部分中，您学习了如何创建数字签名，以及如何对 PowerShell 文件签名。现在我们来看看如何验证脚本的合法性。

```powershell
# this is the path to the scripts you'd like to examine
$Path = "$home\Documents"

Get-ChildItem -Path $Path -Filter *.ps1 -Recurse |
    Get-AuthenticodeSignature
```

只需要调整路径，该脚本讲查找该路径下的所有 PowerShell 脚本，然后检查它们的签名。结果有如下可能性：

    NotSigned:	没有签名
    UnknownError:	使用非受信的证书签名
    HashMismatch:	签名之后修改过
    Valid:		采用受信任的证书签名，并且没有改动过

<!--more-->
本文国际来源：[Code-Signing Mini-Series (Part 5: Auditing Signatures)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/code-signing-mini-series-part-5-auditing-signatures)
