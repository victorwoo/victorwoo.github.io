---
layout: post
date: 2019-08-12 00:00:00
title: "PowerShell 技能连载 - 验证 Active Directory 凭据"
description: PowerTip of the Day - Validating Active Directory Credentials
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 可以通过 Active Directory 验证 AD 用户名和密码：

```powershell
Add-Type -AssemblyName System.DirectoryServices.AccountManagement
$account = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([DirectoryServices.AccountManagement.ContextType]::Domain, $env:userdomain)

$account.ValidateCredentials('user12', 'topSecret')
```

请注意这种方法只能作为诊断目的。它以明文的方式输入密码。

<!--本文国际来源：[Validating Active Directory Credentials](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/validating-active-directory-credentials)-->

