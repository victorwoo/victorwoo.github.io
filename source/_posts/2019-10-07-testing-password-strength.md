---
layout: post
date: 2019-10-07 00:00:00
title: "PowerShell 技能连载 - 测试"
description: PowerTip of the Day - Testing Password Strength
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在之前的技能中，我们讨论过了类似 haveIbeenpwned.com 的服务。它们从之前的黑客攻击中收集泄露的密码，这样您就可以检查您的密码是否已被泄露，并可能被包括在未来的字典攻击中。

以下是两个有用的函数：`Test-Password` 请求一个 SecureString。当您收到提示时，输入将会被屏蔽。接下来 `Convert-SecureStringToText` 将会将整个密码转为纯文本。然后 `Test-Password` 将把输入的整个密码进行哈希运算，并只发送前 5 个字节到 WEB 服务。您的原始密码永远不会泄露。

Web 服务将返回所有以该 5 个字节开头的泄露的密码哈希，这样您就可以检查返回的哈希中是否包含您的哈希。

如果您的密码在之前的攻击中出现，那么您将受到它在攻击中出现的次数。任何返回大于 0 的数字的密码都必须视为不安全的，并且不该使用。

请记住：当某个密码返回一个大于 0 的数字时，这并不意味着您的密码被破解了。它的意思是，在世界上所有地方中，您的密码在攻击中出现，所以要么您或者其他人使用它并且被黑客攻击：该密码现在不安全并且已成为攻击字典的一部分，黑客会尝试账户。如果您继续使用这个密码，黑客有可能在不就得将来利用简单（快速）的字典攻击来破解它。

在之前的提示中，我们已经讨论了haveIbeenpwned.com等服务。他们从以前的黑客攻击中收集泄露的密码，这样你就可以检查你的密码是否已被泄露，并可能被包括在未来的字典攻击中。

下面有两个有用的函数:Test-Password请求SecureString，因此当您收到提示时，您的输入将被屏蔽。然后将输入的密码转换为纯文本。然后，Test-Password散列您输入的密码，只将前5个字节发送给web服务。您的原始密码永远不会泄露。

web服务将返回所有以您的5个字节开头的密码散列，因此您可以检查返回的散列是否与您的散列匹配。

如果您的密码在以前的攻击中被发现，您将收到它参与攻击的次数。任何返回大于0的数字的密码都被认为是不安全的，不应该使用。

请记住:当密码返回一个大于0的数字时，这并不意味着您自己的密码被破解了。它的意思是，在世界上任何地方，你的密码在攻击中出现，所以要么你或其他人使用它并被黑客攻击。无论是你还是别人:这个密码现在是不安全的，因为它成为黑客攻击字典的一部分，黑客会尝试帐户。如果你继续使用这个密码，黑客很有可能在不久的将来利用简单(快速)的字典攻击来破解它。

```powershell
function Convert-SecureStringToText{
  param  (
    [Parameter(Mandatory,ValueFromPipeline)]
    [System.Security.SecureString]
    $Password  )

  process  {
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
    [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
  }
}function Test-Password
{  [CmdletBinding()]
  param  (
    [Parameter(Mandatory, Position=0)]
    [System.Security.SecureString]
    $Password  )

  $plain = $Password | Convert-SecureStringToText
  $bytes = [Text.Encoding]::UTF8.GetBytes($plain)
  $stream = [IO.MemoryStream]::new($bytes)
  $hash = Get-FileHash -Algorithm 'SHA1' -InputStream $stream  $stream.Close()
  $stream.Dispose()

  $first5hashChars,$remainingHashChars = $hash.Hash -split '(?<=^.{5})'
  $url = "https://api.pwnedpasswords.com/range/$first5hashChars"  [Net.ServicePointManager]::SecurityProtocol = 'Tls12'  $response = Invoke-RestMethod -Uri $url -UseBasicParsing
  $lines = $response -split '\r\n'  $filteredLines = $lines -like "$remainingHashChars*"
  [int]($filteredLines -split ':')[-1]
}
```

<!--本文国际来源：[Testing Password Strength](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/testing-password-strength)-->

