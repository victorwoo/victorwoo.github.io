layout: post
date: 2017-04-11 00:00:00
title: "PowerShell 技能连载 - 直接导入证书（第一部分）"
description: PowerTip of the Day - Directly Importing Certificates (Part 1)
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
可以在任意版本的 PowerShell 中用 .NET 方法将证书安装到计算机中。这将导入一个证书文件到个人存储中：

```powershell
# importing to personal store
$Path = 'C:\Path\To\CertFile.cer'
$Store = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Store -ArgumentList My, CurrentUser
$Store.Open('ReadWrite')
$Store.Add($Path)
$Store.Close()
```

您可以打开证书管理器证实这一点：

```powershell
PS C:\> certmgr.msc
```

如果您想将证书导入到一个不同的存储位置，只需要调整创建存储对象的参数即可。

<!--more-->
本文国际来源：[Directly Importing Certificates (Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/directly-importing-certificates-part-1)
