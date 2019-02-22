---
layout: post
date: 2017-12-19 00:00:00
title: "PowerShell 技能连载 - 将机器加入域"
description: PowerTip of the Day - Joining Computers to a Domain
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
以下是 PowerShell 将机器加入 AD 域的基本步骤：

```powershell
# do not store passwords in production solutions,
# or you MUST control access permissions to this sensitive data
$username = "mydomain\UserName"
$password = 'Password' | ConvertTo-SecureString -AsPlainText -Force
$domainName = 'NameOfDomain'

# convert username and password to a credential
$cred = [PSCredential]::new($username, $password)
# join computer
Add-Computer -DomainName $domainName -Credential $cred
# restart computer
Restart-Computer
```

您可以根据需要修改这段代码。这个例子中用明文存储密码，这是不安全的。您可能需要从一个文件中读取密码。

<!--本文国际来源：[Joining Computers to a Domain](http://community.idera.com/powershell/powertips/b/tips/posts/joining-computers-to-a-domain)-->
