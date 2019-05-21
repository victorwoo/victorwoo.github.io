---
layout: post
date: 2019-05-17 00:00:00
title: "PowerShell 技能连载 - 获取文本的哈希值"
description: PowerTip of the Day - Get Hashes from Texts
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerShell 5（以及 `Get-FileHash` 之前），要计算字符串和文件的哈希值，您需要借助原生的 .NET 方法。以下是一段为一个字符串创建 MD5 哈希的示例代码：

```powershell
$Text = 'this is the text that you want to convert into a hash'

$Provider = New-Object -TypeName Security.Cryptography.MD5CryptoServiceProvider
$Encodiner = New-Object -TypeName Text.UTF8Encoding

$Bytes = $Encodiner.GetBytes($Text)
$hashBytes = $Provider.ComputeHash($Bytes)
$hash = [System.BitConverter]::ToString($hashBytes)

# remove dashes if needed
$hash -replace '-'
```

如果您需要计算一个文件内容的哈希值，要么使用 `Get-Content` 来读取文件，或者使用以下代码：

```powershell
$Path = "C:\somefile.txt"

# use your current PowerShell host as a sample
$Path = Get-Process -Id $Pid | Select-Object -ExpandProperty Path

$Provider = New-Object -TypeName Security.Cryptography.MD5CryptoServiceProvider
$FileContent = [System.IO.File]::ReadAllBytes($Path)
$hashBytes = $Provider.ComputeHash($FileContent)
$hash = [System.BitConverter]::ToString($HashBytes)

$hash -replace '-'
```

<!--本文国际来源：[Get Hashes from Texts](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/get-hashes-from-texts)-->

