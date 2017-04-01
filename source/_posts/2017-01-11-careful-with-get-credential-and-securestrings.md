layout: post
date: 2017-01-11 00:00:00
title: "PowerShell 技能连载 - 小心 Get-Credential 和 SecureString"
description: PowerTip of the Day - Careful with Get-Credential and SecureStrings
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
有些时候，脚本以交互的方式询问凭据或密码。请时刻注意脚本的作者可以获取所有输入信息的明文。仅当您信任脚本和作者的时候才可以输入敏感信息。

请注意：这并不是一个 PowerShell 问题，这是所有软件的共同问题。

让我们看看一个脚本如何利用输入的密码。如果一个脚本需要完整的凭据，它可以检查凭据对象并解出密码明文：

```powershell
$credential = Get-Credential
$password = $credential.GetNetworkCredential().Password

"The password entered was: $password"
```

类似地，当提示您输入密码作为安全字符串时，脚本的作者也能获取到输入的明文：

```powershell
$password = Read-Host -AsSecureString -Prompt 'Enter Password'

# this is how the owner of a secure string can get back the plain text:
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
$plaintext = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

"The password entered was $plaintext"
```

<!--more-->
本文国际来源：[Careful with Get-Credential and SecureStrings](http://community.idera.com/powershell/powertips/b/tips/posts/careful-with-get-credential-and-securestrings)
