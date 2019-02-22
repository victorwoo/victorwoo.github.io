---
layout: post
date: 2018-11-27 00:00:00
title: "PowerShell 技能连载 - 将安全字符串转换为明文"
description: PowerTip of the Day - Converting SecureString to Clear Text
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
安全字符串的内容并不能很轻易地查看：

```powershell
$password = Read-Host -Prompt 'Your password' -AsSecureString



PS C:\> $password
System.Security.SecureString
```

然而，如果您是第一个要求安全字符串的人，您可以用这个聪明的技巧轻松地将它转换为纯文本：

```powershell
$txt = [PSCredential]::new("X", $Password).GetNetworkCredential().Password
$txt
```

本质上，`SecureString` 是用来创建一个 `PSCredential` 对象，并且一个 `PSCredential` 对象包含了 `GetNetworkCredential()` 方法，它能够自动地将加密的密码转换为明文。

通过这种方式，您可以使用 `Red-Hsot -AsSecureString` 提供的遮罩输入框来输入敏感信息，即便您需要该信息的明文字符串：

```powershell
function Read-HostSecret([Parameter(Mandatory)]$Prompt)
{
    $password = Read-Host -Prompt $Prompt -AsSecureString
    [PSCredential]::new("X", $Password).GetNetworkCredential().Password
}



PS C:\> Read-HostSecret -Prompt 'Your secret second first name'
Your secret second first name: ********
Valentin

PS C:\>
```

<!--本文国际来源：[Converting SecureString to Clear Text](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/converting-securestring-to-clear-text)-->
