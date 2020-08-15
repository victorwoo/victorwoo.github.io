---
layout: post
date: 2020-08-10 00:00:00
title: "PowerShell 技能连载 - 验证用户帐户密码（第 1 部分）"
description: PowerTip of the Day - Validating User Account Passwords (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 可以为您测试用户帐户密码。这适用于本地帐户和域帐户。这是一个称为 `Test-Password` 的示例函数：

```powershell
function Test-Password
{
   param
   (
      [Parameter(Mandatory)]
      [string]
      $Domain,

      [Parameter(Mandatory)]
      [string]
      $Username,

      [Parameter(Mandatory)]
      [string]
      $Password

   )

   # load assembly for required system commands
   Add-Type -AssemblyName System.DirectoryServices.AccountManagement


   # is this a local user account?
   $local = $Domain -eq $env:COMPUTERNAME

   if ($local)
   {
      $context = [System.DirectoryServices.AccountManagement.ContextType]::Machine
   }
   else
   {
      $context = [System.DirectoryServices.AccountManagement.ContextType]::Domain
   }
   # test password
   $PrincipalContext = [System.DirectoryServices.AccountManagement.PrincipalContext]::new($context, $Domain)
   $PrincipalContext.ValidateCredentials($UserName,$Password)
}
```

它需要域名（或本地计算机名），用户名和密码。密码正确时，该函数返回 `$true`。

请注意，此处使用的系统方法需要明文密码。输入明文密码并不安全，因此在我们的下一个技巧中，我们将改进以隐藏方式提示密码的功能。

<!--本文国际来源：[Validating User Account Passwords (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/validating-user-account-passwords-part-1)-->

