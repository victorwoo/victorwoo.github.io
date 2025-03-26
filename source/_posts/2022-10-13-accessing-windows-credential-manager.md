---
layout: post
date: 2022-10-13 00:00:00
title: "PowerShell 技能连载 - 存取 Windows 凭据管理器"
description: PowerTip of the Day - Accessing Windows Credential Manager
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您需要访问 Windows 凭据管理器存储的凭据（已保存的密码），则 "CredentialManager" 模块可能有所帮助。运行此代码下载并安装它：

```powershell
Install-Module -Name CredentialManager -Scope CurrentUser
```

安装该模块后，您可以列出其提供的新命令：

```powershell
PS> Get-Command -Module CredentialManager

CommandType Name                    Version Source
----------- ----                    ------- ------
Cmdlet      Get-StoredCredential    2.0     CredentialManager
Cmdlet      Get-StrongPassword      2.0     CredentialManager
Cmdlet      New-StoredCredential    2.0     CredentialManager
Cmdlet      Remove-StoredCredential 2.0     CredentialManager
```

`Get-StoredCredential` 获取存储的凭据。并且 `New-StoredCredential` 可以与凭据管理器一起存储凭据：
获得存储的存储凭据。 而且，新存储者可以为您与凭据管理器一起存储凭据：

```powershell
New-StoredCredential -Target MyCred -Credentials (Get-Credential) -Type Generic -Persist LocalMachine
```

现在，当脚本需要访问存储的凭据时，请像这样使用 `Get-StoredCredential`：

```powershell
$cred = Get-StoredCredential -Target MyCred
# show clear text information
$cred.UserName
$cred.GetNetworkCredential().Password
```

Windows 凭据管理器安全地为本地用户存储凭据。只有最初保存凭据的用户才能检索它。

<!--本文国际来源：[Accessing Windows Credential Manager](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/accessing-windows-credential-manager)-->

