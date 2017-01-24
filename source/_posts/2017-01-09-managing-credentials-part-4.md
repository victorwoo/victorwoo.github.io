layout: post
date: 2017-01-08 16:00:00
title: "PowerShell 技能连载 - 管理凭据（第四部分）"
description: PowerTip of the Day - Managing Credentials (Part 4)
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
在前一个脚本中我们演示了如何以加密的方式将一个凭据保存到磁盘上。一个类似的方法只将密码保存到加密的文件中。这段代码将创建一个加密的密码文件：

```powershell
# read in the password, and save it encrypted
$text = Read-Host -AsSecureString -Prompt 'Enter Password'
$text | Export-Clixml -Path "$home\desktop\mypassword.xml"
```

它只能由保存的人读取，而且必须在同一台机子上操作。第二个脚本可以用该密码登录其它系统而无需用户交互：

```powershell
# read in the secret and encrypted password from file
$password = Import-Clixml -Path "$home\desktop\mypassword.xml"

# add the username and create a credential object
$username = 'yourCompany\yourUserName'
$credential = New-Object -TypeName PSCredential($username, $password)
```

凭据对象可以用在所有支持 `-Credential` 参数的 cmdlet 中。

```powershell
# use the credential with any cmdlet that exposes the –Credential parameter
# to log in to remote systems
Get-WmiObject -Class Win32_LogicalDisk -ComputerName SomeServer -Credential $credential
```

<!--more-->
本文国际来源：[Managing Credentials (Part 4)](http://community.idera.com/powershell/powertips/b/tips/posts/managing-credentials-part-4)
