---
layout: post
date: 2020-08-14 00:00:00
title: "PowerShell 技能连载 - 验证用户账户密码（第 3 部分）"
description: PowerTip of the Day - Validating User Account Passwords (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前面的部分中，我们创建了 `Test-Password` 函数，该函数可以测试本地和远程用户的密码。

在最后一部分，我们将错误处理添加到 `Test-Password` 函数中，以便当用户输入不存在或不可用的域时它可以正常响应：

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

   try
   {
      $PrincipalContext = [System.DirectoryServices.AccountManagement.PrincipalContext]::new($context, $Domain)
      $PrincipalContext.ValidateCredentials($UserName,$plain)
   }
   catch [System.DirectoryServices.AccountManagement.PrincipalServerDownException]
   {
      throw "Test-Password: Domain '$Domain' not found."
   }
}
```

运行此代码后，将有一个新命令 "`Test-Password`"。运行它时，系统会提示您输入域（或用于测试本地帐户的本地计算机名称），用户名和掩码密码。

下面是在 PowerShell 7 中运行的示例：第一次调用（测试本地帐户）成功，并产生 `$true`。第二个调用（指定一个不可用的域）失败，并显示一条自定义错误消息：

```powershell
PS C:\> Test-Password

cmdlet Test-Password at command pipeline position 1
Supply values for the following parameters:
Domain: dell7390
Username: remotinguser2
Password: ***********
True
PS C:\> Test-Password

cmdlet Test-Password at command pipeline position 1
Supply values for the following parameters:
Domain: doesnotexist
Username: testuser
Password: ********
Exception:
Line |
  47 |        throw "Test-Password: Domain '$Domain' not found."
     |        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Test-Password: Domain 'doesnotexist' not found.
```

<!--本文国际来源：[Validating User Account Passwords (Part 3)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/validating-user-account-passwords-part-3)-->

