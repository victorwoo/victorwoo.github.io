---
layout: post
date: 2017-12-14 00:00:00
title: "PowerShell 技能连载 - 将用户名转换为 SID"
description: PowerTip of the Day - Converting User Name to SID
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
以下代码演示了如何查找一个用户名的 SID：

```powershell
$domain = 'MyDomain'
$username = 'User01'
```

```powershell
$sid = (New-Object Security.Principal.NTAccount($domain, $username)).Translate([Security.Principal.SecurityIdentifier]).Value

$sid
```

只需要确保正确地调整了域名和用户名。如果您需要查看本地用户的 SID，只需要将域名设置为本地计算机的名称。

```powershell
$username = 'Administrator'

$sid = (New-Object Security.Principal.NTAccount($env:computername, $username)).Translate([Security.Principal.SecurityIdentifier]).Value

$sid
```

这在 PowerShell 5 中更简单，因为有一个新的 `Get-LocalUser` cmdlet：

```powershell
PS C:\> Get-LocalUser | Select-Object -Property Name, Sid

Name           SID
----           ---
Administrator  S-1-5-21-2951074159-1791007430-3873049619-500
CCIE           S-1-5-21-2951074159-1791007430-3873049619-1000
DefaultAccount S-1-5-21-2951074159-1791007430-3873049619-503
Guest          S-1-5-21-2951074159-1791007430-3873049619-501
```

<!--本文国际来源：[Converting User Name to SID](http://community.idera.com/powershell/powertips/b/tips/posts/converting-user-name-to-sid)-->
