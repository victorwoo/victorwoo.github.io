---
layout: post
date: 2022-05-18 00:00:00
title: "PowerShell 技能连载 - 签名 PowerShell 脚本（第 1 部分）"
description: PowerTip of the Day - Code-Signing PowerShell Scripts (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如今，将数字签名添加到 PowerShell 脚本不再是黑魔法，尽管理想情况下需要从公司或可信赖的权威中获得正式的“信任”代码签名证书，但现在不再是强制性的。

在进行代码签名之前，首先了解为什么要对 PowerShell 脚本进行签名？

数字签名是脚本代码的哈希，并使用数字证书的私钥进行加密。将其视为针对脚本的“包装器”或“密封”。有了它，您现在可以随时分辨出某人是否篡改了您的脚本。没有它，您将无法实现这个目的。

如果您尚未拥有适合代码签名的数字证书，那么在 Windows 机器上，您可以使用 `New-SelfSignedCertificate` cmdlet 快速创建一个。

运行此行代码以创建自己的全新代码签名证书，并将其存储在您的个人证书存储中（除非您使用 `-NotAfter` 指定不同的到期日期，否则有效期为一年）：

```powershell
PS> New-SelfSignedCertificate -Subject MyPowerShellCode -Type CodeSigningCert -CertStoreLocation Cert:\CurrentUser\my -FriendlyName 'My Valid PowerShell Code'


    PSParentPath: Microsoft.PowerShell.Security\Certificate::CurrentUser\my

Thumbprint                                Subject
----------                                -------
57402F9D82231CABA4586127C99819F055AA2AF2  CN=MyPowerShellCode
```

要稍后在任何时候检索它，请记住它的指纹并像这样访问它（修改指纹以匹配您的其中一个证书）：

```powershell
PS> $cert = Get-Item -Path Cert:\CurrentUser\My\57402F9D82231CABA4586127C99819F055AA2AF2

PS> $cert.Subject
CN=MyPowerShellCode

PS> $cert.FriendlyName
My Valid PowerShell Code

PS> $cert.NotAfter

Monday, May 1, 2023 17:47:43
```

或者，如果您只记得主题或友好名称，则可以使用过滤器：

```powershell
PS> Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert | Where-Object Subject -like *MyPowerShell*


    PSParentPath: Microsoft.PowerShell.Security\Certificate::CurrentUser\My

Thumbprint                                Subject
----------                                -------
57402F9D82231CABA4586127C99819F055AA2AF2  CN=MyPowerShellCode
```

在下一个技能中，我们将开始使用此证书签署 PowerShell 脚本。

<!--本文国际来源：[Code-Signing PowerShell Scripts (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/code-signing-powershell-scripts-part-1)-->

