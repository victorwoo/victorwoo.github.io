---
layout: post
date: 2018-11-30 00:00:00
title: "PowerShell 技能连载 - 代码签名迷你系列（第 3 部分：从个人存储中读取证书）"
description: 'PowerTip of the Day - Code-Signing Mini-Series (Part 3: Reading Certificates from Personal Store)'
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
可以通过加载至 Windows 证书存储的方式永久地安装证书。PowerShell 可以通过 `cert:` 驱动器存取这个存储。以下这行代码将显示所有个人证书：

```powershell
PS C:\> Get-ChildItem -Path Cert:\CurrentUser\my


    PSParentPath: Microsoft.PowerShell.Security\Certificate::CurrentUser\my

Thumbprint                                Subject
----------                                -------
9F2F02100F6AE1DA83628906D60267F89377A6B2  CN=König von Timbuktu (Ost)
65C5ED677C9EEE9AB8D8F55354E920313FE427C2  CN=UniYork IT Security
322CA0B1F37F43B26D4D8DE17DCBF3E2C17CE111  CN=Tobias
```

请注意：如果您的个人证书存储是空的，您可能需要查看这个系列之前的文章来创建一些测试证书。

要只查看代码签名证书，请添加 `-CodeSigningCert` 动态参数。这将排除所有其它用途的证书以及没有私钥的证书：

```powershell
PS C:\> Get-ChildItem -Path Cert:\CurrentUser\my -CodeSigningCert
```

证书是以它们唯一的指纹 ID 标识，它就像文件的名字一样：

```powershell
PS C:\> Get-ChildItem -Path Cert:\CurrentUser\my


    PSParentPath: Microsoft.PowerShell.Security\Certificate::CurrentUser\my

Thumbprint                                Subject
----------                                -------
9F2F02100F6AE1DA83628906D60267F89377A6B2  CN=King of Timbuktu (Eastside)
65C5ED677C9EEE9AB8D8F55354E920313FE427C2  CN=UniYork IT Security
322CA0B1F37F43B26D4D8DE17DCBF3E2C17CE111  CN=Tobias


PS C:\> $cert = Get-Item -Path Cert:\CurrentUser\My\9F2F02100F6AE1DA83628906D60267F89377A6B2

PS C:\> $cert


    PSParentPath: Microsoft.PowerShell.Security\Certificate::CurrentUser\My

Thumbprint                                Subject
----------                                -------
9F2F02100F6AE1DA83628906D60267F89377A6B2  CN=King of Timbuktu (Eastside)
```

如果还不知道唯一的指纹 ID，您需要先找出它，因为这个 ID 能够唯一确认证书。一个查找的方法是按其它属性过滤，例如 subject：

```powershell
PS C:\> dir Cert:\CurrentUser\my | where subject -like *tobias*


    PSParentPath: Microsoft.PowerShell.Security\Certificate::CurrentUser\my

Thumbprint                                Subject
----------                                -------
322CA0B1F37F43B26D4D8DE17DCBF3E2C17CE111  CN=Tobias
```

在本迷你系列的第一部分，已经介绍了如何用 PowerShell 创建新的证书。

现在您已经学习了如何从 pfx 文件和个人证书存储中读取已有的证书。

请关注下一个技能来学习如何使用证书来实际签名 PowerShell 代码！

<!--more-->
本文国际来源：[Code-Signing Mini-Series (Part 3: Reading Certificates from Personal Store)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/code-signing-mini-series-part-3-reading-certificates-from-personal-store)
