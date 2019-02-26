---
layout: post
date: 2019-02-21 00:00:00
title: "PowerShell 技能连载 - 验证本地用户账户密码"
description: PowerTip of the Day - Verifying Local User Account Passwords
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能VS，我们通过 Active Directory 来验证用户账户密码。同样的，对于本地账户也可以。PowerShell 代码可以使用本地账户密码来管理对脚本的存取，或部分限制脚本的功能。当然，您也可以用以下代码来创建自己的基本的密码穷举工具。

缺省情况下，以下代码使用您当前的用户名。请确保 `$UserName` 是某个本地账户的用户名：

```powershell
# specify local user name and password to test
$UserName = $env:USERNAME
$Password = Read-Host -Prompt "Enter password to test"

# test password
Add-Type -AssemblyName System.DirectoryServices.AccountManagement 
$type = [DirectoryServices.AccountManagement.ContextType]::Machine
$PrincipalContext = [DirectoryServices.AccountManagement.PrincipalContext]::new($type)
$PrincipalContext.ValidateCredentials($UserName,$Password)
```

今日的知识点：

* PowerShell 可以请求本地的 Windows 用户数据库来验证密码。通过这种方式，您可以使用 Windows 维护的密码来决定一个脚本是否允许执行，或允许某个用户执行哪一部分。
* 请注意向用户询问密码是一种不安全的做法，因为他们不知道密码将会被用在什么地方。

<!--本文国际来源：[Verifying Local User Account Passwords](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/verifying-local-user-account-passwords)-->
