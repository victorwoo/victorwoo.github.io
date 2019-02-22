---
layout: post
date: 2017-01-04 00:00:00
title: "PowerShell 技能连载 - 管理凭据（第一部分）"
description: PowerTip of the Day - Managing Credentials (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
假设您每天都要运行一个需要凭据的脚本。一个使用强壮凭据的安全方法是将它们保存到一个加密的文件中。这段代码提示输入凭据，然后将它们保存到您桌面上的 XML 文件中：

```powershell
$credential = Get-Credential -UserName train\user02 -Message 'Please provide credentials' 
$credential | Export-Clixml -Path "$home\desktop\myCredentials.xml"
```

密码是以您的身份加密的，所以只有您（并且只能在保存凭据的机器上）能存取该凭据。

以下是读取保存的凭据的代码：

```powershell
$credential = Import-Clixml -Path "$home\desktop\myCredentials.xml"

# use the credential with any cmdlet that exposes the –Credential parameter
# to log in to remote systems
Get-WmiObject -Class Win32_LogicalDisk -ComputerName SomeServer -Credential $credential
```

<!--本文国际来源：[Managing Credentials (Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/managing-credentials-part-1)-->
