---
layout: post
date: 2017-01-06 00:00:00
title: "PowerShell 技能连载 - 管理凭据（第三部分）"
description: PowerTip of the Day - Managing Credentials (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
对于无人值守的脚本，以硬编码的方式将密码保存在脚本中是不安全且不推荐的。

有一种替代方法是，您可以一次性提示输入密码，然后创建一个凭据对象，然后在您的脚本中需要的地方使用它。这段代码提示输入一个密码，然后创建一个凭据对象：

```powershell
$password = Read-Host -AsSecureString -Prompt 'Enter Password'
$username = 'myCompany\myUserName'
$credential = New-Object -TypeName PSCredential($username, $password)
```

平局对象可以用在任何接受 `-Credential` 参数的 cmdlet 中。

```powershell
# use the credential with any cmdlet that exposes the –Credential parameter
# to log in to remote systems
Get-WmiObject -Class Win32_LogicalDisk -ComputerName SomeServer -Credential $credential
```

<!--more-->
本文国际来源：[Managing Credentials (Part 3)](http://community.idera.com/powershell/powertips/b/tips/posts/managing-credentials-part-3)
