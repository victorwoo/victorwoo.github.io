---
layout: post
date: 2017-09-27 00:00:00
title: "PowerShell 技能连载 - 操作 PowerShell Gallery 内容"
description: PowerTip of the Day - Playing with PowerShell Gallery Content
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
公共的 PowerShell Gallery ([www.powershellgallery.com](http://www.powershellgallery.com)) 是一个 PowerShell 脚本作者们可以自由地交换脚本和模块的地方。您所需要的只是包含 PowerShellGet 的 PowerShell 5，它带了操作 Gallery 需要的 cmdlet。

当然，您需要自己确认代码，确保它可以完美运行，并且没有安全问题。

有一个模块叫做“PSCredentialManager”。以下是如何查看这个模块信息的方法：


```powershell
PS> Find-Module -Name PSCredentialManager | Select-Object -Property *


Name                       : pscredentialmanager
Version                    : 1.0.1
Type                       : Module
Description                : This module allows management and automation of Windows cached credentials.
Author                     : Adam Bertram
CompanyName                : adamtheautomator
Copyright                  : (c) 2017 Adam Bertram. All rights reserved.
PublishedDate              : 18.06.2017 22:14:27
...
```

要安装这个模块，请运行以下代码：

```powershell
PS> Install-Module -Name PSCredentialManager -Scope CurrentUser -RequiredVersion 0.6
```

请注意我们显式地要求安装 0.6 版。在写这篇文章的时候，还有个 1.0.1 版，但存在一些问题。当您从一个公开的地方，例如 PowerShell Gallery 中获取内容，随时有可能得到非预期的结果，请留意。

如果您希望在安装一个模块前检查它的代码，可以使用 `Save-Module`，将模块下载到一个隔离的地方。

```powershell
PS> Find-Module pscredentialmanager -AllVersions

Version    Name                    Repository           Description
-------    ----                    ----------           -----------
1.0.1      pscredentialmanager     PSGallery            This module allows
0.6        pscredentialmanager     PSGallery            This module allows
0.2        pscredentialmanager     PSGallery            This module allows
```

安装完成后，以下命令可以返回一个新 cmdlet 的列表：

```powershell
PS> Get-Command -Module pscredentialmanager

CommandType     Name                                               Version    Source
-----------     ----                                               -------    ------
Function        Get-CachedCredential                               0.6        pscredentialmanager
Function        New-CachedCredential                               0.6        pscredentialmanager
Function        Remove-CachedCredential                            0.6        pscredentialmanager
```

您现在可以管理缓存的凭据。例如要返回一个缓存的凭据列表，请试试以下代码：

```powershell
PS> Get-CachedCredential


Name        : SSO_POP_User
Category    : MicrosoftAccount
Type        : Domain Extended Credentials
(...)
```

如果您想看看新的 cmdlet（也叫函数）如何工作，您还可以阅读它的源码。这行代码将函数的源码复制到剪贴板：

```powershell
PS> ${function:Get-CachedCredential} | clip
```

要弃用这个模块，只需要卸载它：

```powershell
PS> Uninstall-Module -Name pscredentialmanager -AllVersions
```

<!--本文国际来源：[Playing with PowerShell Gallery Content](http://community.idera.com/powershell/powertips/b/tips/posts/playing-with-powershell-gallery-content)-->
