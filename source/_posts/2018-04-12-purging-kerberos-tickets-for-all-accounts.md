---
layout: post
date: 2018-04-12 00:00:00
title: "PowerShell 技能连载 - 清除所有账户的 Kerberos 票证"
description: PowerTip of the Day - Purging Kerberos Tickets for All Accounts
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
在前一个技能中我们介绍了 `klist.exe` 以及如何用它来清除当前用户的所有 Kerberos 票证，这样新的权限可以立即生效。

由于 PowerShell 可以很好地调用外部应用程序，例如 `klist.exe`，所以结合其它 PowerShell 命令，功能可以变得更强大。以下代码可以获取所有非使用 NTLM（例如 Kerberos 会话）的登录会话：

```powershell
Get-WmiObject -ClassName Win32_LogonSession -Filter "AuthenticationPackage != 'NTLM'"
```

在提权过的 PowerShell 中运行这行代码，将可以看到所有登录会话。只需要做一点小修改，就可以获取十六进制的登录 ID：

```powershell
Get-WmiObject -ClassName Win32_LogonSession -Filter "AuthenticationPackage != 'NTLM'" |
ForEach-Object {[Convert]::ToString($_.LogonId, 16)}
```

要清除所有会话的缓存的 Kerberos 票证，您可以（在提权的 PowerShell 中）运行这段代码：

```powershell
Get-WmiObject -ClassName Win32_LogonSession -Filter "AuthenticationPackage != 'NTLM'" |
ForEach-Object {[Convert]::ToString($_.LogonId, 16)} |
ForEach-Object { klist.exe purge -li $_ }
```

<!--more-->
本文国际来源：[Purging Kerberos Tickets for All Accounts](http://community.idera.com/powershell/powertips/b/tips/posts/purging-kerberos-tickets-for-all-accounts)
