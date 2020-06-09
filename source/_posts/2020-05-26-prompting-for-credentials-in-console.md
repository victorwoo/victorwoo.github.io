---
layout: post
date: 2020-05-26 00:00:00
title: "PowerShell 技能连载 - 在控制台中提示输入凭据"
description: PowerTip of the Day - Prompting for Credentials in Console
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您运行 `Get-Credential` 或提示您输入用户名和密码时，Windows PowerShell （powershell.exe） 始终会打开一个单独的凭据对话框。而新的 PowerShell 7 (pwsh.exe) 则在控制台内提示：

```powershell
PS> Get-Credential

PowerShell credential request
Enter your credentials.
User: Tobias
Password for user Tobias: ******


UserName                     Password
--------                     --------
Tobias   System.Security.SecureString
```

如果您更喜欢控制台提示而不是打开单独的对话框，则可以切换 Windows PowerShell 的默认行为。您需要管理员特权才能更改注册表设置：

```powershell
$key = "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds"
Set-ItemProperty -Path $key -Name ConsolePrompting -Value $true
```

若要恢复默认行为，请将值更改为 `$false`，或通过 `Remove-ItemProperty` 删除注册表值。

<!--本文国际来源：[Prompting for Credentials in Console](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/prompting-for-credentials-in-console)-->

