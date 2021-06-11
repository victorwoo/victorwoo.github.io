---
layout: post
date: 2020-05-14 00:00:00
title: "PowerShell 技能连载 - 检测泄露的密码（第 1 部分）"
description: PowerTip of the Day - Identifying Compromised Passwords (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
密码复杂时也不一定是安全的。相反，您需要确保密码没有受到破坏，并且不在默认的攻击者词典中。如果自动攻击经常检查该密码，那么即使是最复杂的密码也不安全。

要确定密码是否被泄露，请使用以下功能：

```powershell
function Test-Password
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory, Position=0)]
    [System.Security.SecureString]
    $Password
  )

  # take securestring and get the entered plain text password
  # we are using a securestring only to get a masked input box
  $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
  $plain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

  # hash the password
  $bytes = [Text.Encoding]::UTF8.GetBytes($plain)
  $stream = [IO.MemoryStream]::new($bytes)
  $hash = Get-FileHash -Algorithm 'SHA1' -InputStream $stream
  $stream.Close()
  $stream.Dispose()

  # separate the first 5 hash characters from the rest
  $first5hashChars,$remainingHashChars = $hash.Hash -split '(?<=^.{5})'

  # send the first 5 hash characters to the web service
  $url = "https://api.pwnedpasswords.com/range/$first5hashChars"
  [Net.ServicePointManager]::SecurityProtocol = 'Tls12'
  $response = Invoke-RestMethod -Uri $url -UseBasicParsing

  # split result into individual lines...
  $lines = $response -split '\r\n'
  # ...and get the line where the returned hash matches your
  # remainder of the hash that you kept private
  $filteredLines = $lines -like "$remainingHashChars*"

  # return the number of compromises
  [int]($filteredLines -split ':')[-1]
}
```

使用起来非常简单：只需将密码传给 `Test-Password` 函数即可。它返回已知泄露的数量，并且返回大于 0 泄露的任何密码都被认为是不安全的，必须进行更改。

```powershell
PS> $password = Read-Host -AsSecureString

PS> Test-Password -Password $password
4880
```

密码必须作为 `SecureString` 提交。您可以不带密码运行 `Test-Password`，在这种情况下，系统会提示您。或者您需要以 `SecureString` 形式读取密码。

在该示例中，复杂密码 "P@$$w0rd" 在 4880 次攻击中被泄露，使用起来非常不安全。

<!--本文国际来源：[Identifying Compromised Passwords (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/identifying-compromised-passwords-part-1)-->

