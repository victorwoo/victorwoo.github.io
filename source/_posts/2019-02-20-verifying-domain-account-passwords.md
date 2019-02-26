---
layout: post
date: 2019-02-20 00:00:00
title: "PowerShell 技能连载 - 校验域账户密码"
description: PowerTip of the Day - Verifying Domain Account Passwords
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 可以轻松地校验一个域账号的密码。换句话说，您可以为 Active Directory 维护的密码绑定一个脚本逻辑。

以下是将密码发送到 AD 并获取回一个 Boolean 值的代码：如果密码正确，返回 `$true`，否则返回 `$false`：

```powershell
# specify user name and user domain
$UserDomain = $env:USERDOMAIN
$UserName = $env:USERNAME
$Password = Read-Host -Prompt "Enter password to test"

# test password
Add-Type -AssemblyName System.DirectoryServices.AccountManagement 
$ContextType = [System.DirectoryServices.AccountManagement.ContextType]::Domain
$PrincipalContext = [System.DirectoryServices.AccountManagement.PrincipalContext]::new($ContextType, $UserDomain)
$PrincipalContext.ValidateCredentials($UserName,$Password)
```

请注意这段代码需要 Active Directory 环境，并且不支持本地账号。缺省情况下，它使用您当前账号的详细信息。请根据实际情况调整 `$UserDomain`、`$UserName` 和 `$Password` 变量。也请注意 `ValidateCredentials()` 检查的是明文字符串密码。请谨慎处理并且不要在脚本存储明文密码。同时，不要要求用户以明文输入密码。

今日知识点：

* PowerShell 可以轻松地连接到 Active Directory 并进行密码验证。

<!--本文国际来源：[Verifying Domain Account Passwords](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/verifying-domain-account-passwords)-->
