---
layout: post
date: 2020-05-08 00:00:00
title: "PowerShell 技能连载 - 使 PowerShell 模块保持最新"
description: PowerTip of the Day - Keep PowerShell Modules Up-To-Date
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
务必经常检查您的 PowerShell 模块是否为最新。如果您使用的是旧的和过时的模块，则可能会遇到问题，就像平时使用旧的和过时的软件一样。

例如，PowerShellGet 模块提供了诸如 `Install-Module` 之类的 cmdlet，可让您轻松下载和安装其他 PowerShell 模块，并通过新的命令和功能扩展 PowerShell。

为了了解这一点，下面是一个示例，该示例下载并安装 `QRCodeGenerator` 模块，该模块会生成各种 QR 代码，例如用于 Twitter 个人资料：

```powershell
# install new PowerShell module from PowerShell Gallery
PS> Install-Module -Name QRCodeGenerator -Scope CurrentUser

# use one of the newly added commands to create a QR code for Twitter profiles
PS> New-QRCodeTwitter  -ProfileName tobiaspsp -Show
```

使用智能手机相机扫描创建的 QR 码时，您可以访问 QR 码中编码的 Twitter 个人资料。同样，其他 QR 码类型也可以提供前往某个地点的路线或向您的地址簿添加联系人：

```powershell
PS> Get-Command -Module QRCodeGenerator -CommandType function

CommandType     Name                          Version    Source
-----------     ----                          -------    ------
Function        New-PSOneQRCodeGeolocation    2.2        QRCodeGenerator
Function        New-PSOneQRCodeTwitter        2.2        QRCodeGenerator
Function        New-PSOneQRCodeVCard          2.2        QRCodeGenerator
Function        New-PSOneQRCodeWifiAccess     2.2        QRCodeGenerator
```

如果您在新添加的模块上遇到问题，则可能是因为 PowerShellGet 模块已过时。如果您仍在使用古老的 PowerShellGet 版本 1.0.0.1，则可能会遇到讨厌的错误。

当模块仅使用 manifest 文件中的 major 和 minor 版本号时，`Install-Module` 会将它们安装到具有 3 位数字版本号的子文件夹中。这使已安装的模块不可用。

因此，保持模块最新很重要。PowerShellGet 的最新版本已修复此错误。让我们看一下如何检查和更新模块。

首先，找出您当前使用的模块版本，例如 PowerShellGet：

```powershell
PS> Get-Module -Name PowerShellGet -ListAvailable


    Directory: C:\Program Files\WindowsPowerShell\Modules


ModuleType Version    Name                                ExportedCommands
---------- -------    ----                                ----------------
Script     2.2.1      PowerShellGet                       {Find-Command, Find-DSCResource, Find-Module...}
Script     1.0.0.1    PowerShellGet                       {Install-Module, Find-Module, Save-Module...}
```

在此示例中，安装了两个不同版本的 PowerShellGet模块：初始发行版本1.0.0.1和更新版本2.2.1。要找出您使用的版本，请尝试以下操作：

```powershell
    PS> Import-Module -Name PowerShellGet

    PS> Get-Module -Name PowerShellGet

    ModuleType Version    Name                                ExportedCommands
    ---------- -------    ----                                ----------------
    Script     2.2.1      PowerShellGet                       {Find-Command, Find-DscResource, Find-Module...}
```

接下来，检查是否有可用的较新版本（这要求该模块通过官方 PowerShell 库提供，但并非对所有模块都适用。如果此处未提供您的模块，则需要检查最初提供该模块的实体）：

```powershell
PS> Find-Module -Name PowerShellGet

Version Name          Repository Description
------- ----          ---------- -----------
2.2.3   PowerShellGet PSGallery  PowerShell module with commands for discovering, installing, upd...
```

如果有较新的版本，请先尝试更新模块：

```powershell
PS> Update-Module -Name PowerShellGet

PS> Get-Module -Name PowerShellGet -ListAvailable

    Directory: C:\Users\tobia\OneDrive\Dokumente\WindowsPowerShell\Modules


ModuleType Version    Name                                ExportedCommands
---------- -------    ----                                -----------
Script     2.2.3      PowerShellGet                       {Find-Command, Find-DSCResource, Find-M...}


    Directory: C:\Program Files\WindowsPowerShell\Modules


ModuleType Version    Name                                ExportedCommands
---------- -------    ----                                ----------------
Script     2.2.1      PowerShellGet                       {Find-Command, Find-DSCResource, Find-M...}
Script     1.0.0.1    PowerShellGet                       {Install-Module, Find-Module, Save-M...}
```

`Update-Module` 要求该模块最初是通过 `Install-Module` 安装的。如果是这样，PowerShell 会知道原始源码库并自动更新该模块。

如果 `Update-Module` 失败，请尝试使用 `-Force` 参数重新安装该模块。如果仍然失败，请添加 `-SkipPublisherCheck` 参数：

```powershell
PS> Install-Module -Name PowerShellGet -Scope CurrentUser -Force -SkipPublisherCheck
```

要验证成功，请确保已加载最新版本：

```powershell
PS> Import-Module -Name PowerShellGet -Force -PassThru

ModuleType Version    Name                                ExportedCommands
---------- -------    ----                                ----------------
Script     2.2.3      PowerShellGet                       {Find-Command, Find-DscResource, Find-Mo...
```

<!--本文国际来源：[Keep PowerShell Modules Up-To-Date](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/keep-powershell-modules-up-to-date)-->

