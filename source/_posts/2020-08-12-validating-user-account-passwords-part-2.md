---
layout: post
date: 2020-08-12 00:00:00
title: "PowerShell 技能连载 - 验证用户账户密码（第 2 部分）"
description: PowerTip of the Day - Validating User Account Passwords (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技巧中，我们展示了 PowerShell 如何验证和测试用户帐户密码，但是该密码是用纯文本形式传入的。让我们进行更改，以使 PowerShell 在输入密码时将其屏蔽。

您可以重用以下用于其他任何 PowerShell 功能的策略，以提示用户输入隐藏的输入。

Here is the function Test-Password:
这是 `Test-Password` 函数：

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
      [SecureString]
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

   # convert SecureString to a plain text
   # (the system method requires clear-text)
   $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
   $plain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

   # test password
   $PrincipalContext = [System.DirectoryServices.AccountManagement.PrincipalContext]::new($context, $Domain)
   $PrincipalContext.ValidateCredentials($UserName,$plain)
}
```

运行它时，系统会提示您输入域（输入计算机名称以测试本地帐户）和用户名。密码以星号方式提示。密码正确时，该函数返回 `$true`，否则返回 `$false`。

请注意如何将提示的 SecureString 在内部转换为纯文本。每当需要屏蔽的输入框时，都可以使用类型为 SecureString 的必需参数，然后在函数内部将 SecureString 值转换为纯文本。

<!--本文国际来源：[Validating User Account Passwords (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/validating-user-account-passwords-part-2)-->

