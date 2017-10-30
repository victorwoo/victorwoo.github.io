---
layout: post
date: 2017-10-26 00:00:00
title: "PowerShell 技能连载 - 从文本生成 MD5 哈希"
description: PowerTip of the Day - Generating MD5 Hashes from Text
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
`Get-FileHash` cmdlet 可以从文件内容生成哈希值。它无法从任意文本生成哈希值。并且只适用于 PowerShell 5 及更高的版本。

以下是一个小的函数，用 .NET Framework 从任意文本生成 MD5 哈希值：

```powershell
Function Get-StringHash
{
    param
    (
        [String] $String,
        $HashName = "MD5"
    )
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($String)
    $algorithm = [System.Security.Cryptography.HashAlgorithm]::Create('MD5')
    $StringBuilder = New-Object System.Text.StringBuilder

    $algorithm.ComputeHash($bytes) |
    ForEach-Object {
        $null = $StringBuilder.Append($_.ToString("x2"))
    }

    $StringBuilder.ToString()
}
```

每段文本都会生成一个唯一（且短小）的哈希值，所以它可以快速地判断文本是否唯一。它也可以用来检查一大段文本是否有变更过。

```powershell
PS C:\> Get-StringHash "Hello World!"
ed076287532e86365e841e92bfc50d8c

PS C:\>
```

<!--more-->
本文国际来源：[Generating MD5 Hashes from Text](http://community.idera.com/powershell/powertips/b/tips/posts/generating-md5-hashes-from-text)
