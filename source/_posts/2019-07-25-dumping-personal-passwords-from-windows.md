---
layout: post
date: 2019-07-25 00:00:00
title: "PowerShell 技能连载 - 从 Windows 中转储个人密码"
description: PowerTip of the Day - Dumping Personal Passwords from Windows
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Windows 有一个受保护的密码库，它可以在其中存储您的密码，因此您不必始终在 InternetExplorer 或 Edge 中手动输入密码。

如果您习惯了自动密码管理器，可能偶尔会忘记原始密码。下面是一个超级简单的 PowerShell 方法来转储存储在 Windows 密码库中的所有密码：

```powershell
# important: this is required to load the assembly
[Windows.Security.Credentials.PasswordVault,Windows.Security.Credentials,ContentType=WindowsRuntime]


(New-Object Windows.Security.Credentials.PasswordVault).RetrieveAll() |
ForEach-Object {
    $_.RetrievePassword()
    $_
} |
Select-Object -Property Username, Password, Resource |
Out-GridView
```

请注意，如果您从未在 InternetExplorer 或 Edge 中存储凭据，则不会得到任何结果。还请注意，此代码设计的工作方式：只有您只能检索密码，就像您在浏览器中访问网站并要求浏览器为您填写凭据一样。

转储所有存储的密码说明了为什么在您不在时始终锁定您的计算机是如此重要。如果您让您的计算机无人值守的话，任何人都可以运行此 PowerShell 代码来转储您的个人密码。

<!--本文国际来源：[Dumping Personal Passwords from Windows](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/dumping-personal-passwords-from-windows)-->

