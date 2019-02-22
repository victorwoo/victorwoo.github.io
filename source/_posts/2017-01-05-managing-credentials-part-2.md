---
layout: post
date: 2017-01-05 00:00:00
title: "PowerShell 技能连载 - 管理凭据（第二部分）"
description: PowerTip of the Day - Managing Credentials (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
对于无人值守运行的脚本，您可以从代码创建登录凭据。这需要将密码以明文的方式存在脚本中（这显然是不安全的，除非您用加密文件系统（EFS）加密您的脚本，或是用其它办法来保护内容）：

```powershell
$password = 'topsecret!' | ConvertTo-SecureString -AsPlainText -Force
$username = 'myCompany\myUserName'
$credential = New-Object -TypeName PSCredential($username, $password) 

# use the credential with any cmdlet that exposes the –Credential parameter
# to log in to remote systems
Get-WmiObject -Class Win32_LogicalDisk -ComputerName SomeServer -Credential $credential
```

<!--本文国际来源：[Managing Credentials (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/managing-credentials-part-2)-->
