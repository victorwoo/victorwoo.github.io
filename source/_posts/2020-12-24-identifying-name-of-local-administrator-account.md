---
layout: post
date: 2020-12-24 00:00:00
title: "PowerShell 技能连载 - 标识本地管理员帐户的名称"
description: PowerTip of the Day - Identifying Name of Local Administrator Account
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有时，PowerShell 脚本需要访问或使用内置的 Administrator 帐户或内置的 Administrators组。不幸的是，它们的名称已本地化，因此它们的名称可以根据 Windows 操作系统的语言进行更改。

但是，它们确实使用了恒定的（众所周知的）SID（安全标识符）。通过使用 SID，您可以获得名称。对于本地 Administrator组，这很简单，因为 SID 始终是已知的：S-1-5-32-544。使用一行代码，可以翻译 SID。这是从德文系统获得的结果：

```powershell
PS> ([Security.Principal.SecurityIdentifier]'S-1-5-32-544').Translate([System.Security.Principal.NTAccount]).Value
VORDEFINIERT\Administratoren
```

使用内置管理员等帐户，就不那么简单了。在此，只有 RID（相对标识符）是已知的：-500。

通过简单的WMI查询，您将获得与过滤器匹配的帐户：

```powershell
PS> Get-CimInstance -ClassName Win32_UserAccount -Filter "LocalAccount = TRUE and SID like 'S-1-5-%-500'"

Name          Caption                AccountType SID                                           Domain
----          -------                ----------- ---                                           ------
Administrator DELL7390\Administrator 512         S-1-5-21-2770831484-2260150476-2133527644-500 DELL7390
```

<!--本文国际来源：[Identifying Name of Local Administrator Account](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/identifying-name-of-local-administrator-account)-->

