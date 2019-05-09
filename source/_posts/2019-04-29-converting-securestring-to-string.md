---
layout: post
date: 2019-04-29 00:00:00
title: "PowerShell 技能连载 - 将 SecureString 转换为字符串"
description: PowerTip of the Day - Converting SecureString to String
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有些时候需要将 SecureString 转换为普通字符串，例如因为您使用了由 `Read-Host` 提供的安全输入：

```powershell
$secret = Read-Host -Prompt 'Enter Keypass' -AsSecureString
```

这将提示用户输入密码，并且输入的内容将变为一个 SecureString：

```powershell
PS> $secret
System.Security.SecureString
```

要将它还原为纯文本，请使用 SecureString 来创建一个 `PSCredential` 对象，它包含了一个解密密码的方法：

```powershell
$secret = Read-Host -Prompt 'Enter Keypass' -AsSecureString
[System.Management.Automation.PSCredential]::new('hehe',$secret).GetNetworkCredential().Password
```

<!--本文国际来源：[Converting SecureString to String](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/converting-securestring-to-string)-->

