---
layout: post
date: 2019-11-06 00:00:00
title: "PowerShell 技能连载 - 探索 PowerShell 模块"
description: PowerTip of the Day - Exploring PowerShell Modules
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
大多数 PowerShell 的命令都存在于模块中，通过增加新的模块，就可以将新的命令添加到 PowerShell 环境中。要查找一个命令是否位于某个模块中，请使用 `Get-Command` 命令。下一行代码返回发布 `Get-Service` 命令的模块：

```powershell
PS C:\> Get-Command -Name Get-Service | Select-Object -ExpandProperty Module
```

如果 `Module` 属性是空值，那么改命令不是通过一个模块发布的。对于所有非 PowerShell 命令，例如应用程序，都是这个情况：

```powershell
PS C:\> Get-Command -Name notepad | Select-Object -ExpandProperty Module
```

下一步，让我们列出您系统中所有可用的模块：

```powershell
PS> Get-Module -ListAvailable | Select-Object -Property Name, Path
```

如果更深入地查看这些结果，您会注意到 `Get-Module` 列出多于一个文件夹。PowerShell 指定的缺省模块文件夹是以分号分隔的列表形式存储在 `$env:PSModulePath` 环境变量中，类似应用程序的 `$env:Path`：

    PS> $env:PSModulePath
    C:\Users\tobia\OneDrive\Dokumente\WindowsPowerShell\Modules;C:\Program Files\WindowsPowerShell\Modules;C:
    \Windows\system32\WindowsPowerShell\v1.0\Modules

    PS> $env:PSModulePath -split ';'
    C:\Users\tobia\OneDrive\Dokumente\WindowsPowerShell\Modules
    C:\Program Files\WindowsPowerShell\Modules
    C:\Windows\system32\WindowsPowerShell\v1.0\Modules

如果您希望探索一个指定模块的内容，请查看 `Path` 属性：它通常指向一个 .psd1 文件，其中包含模块的元数据。它是指定模块版本和版权信息的地方，并且通常它的 `RootModule` 入口指定了模块的代码。如果这是一个使用 PowerShell 代码构建的模块，那么它是一个 .psm1 文件，否则是一个二进制的 DLL 文件。

要检查模块内容，请在 Windows 资源管理器中打开它的父文件夹。例如，下面一行代码在 Windows 资源管理器中打开 "PrintManagement" 模块（假设它存在于您的机器中）：

```powershell
PS> Get-Module -Name PrintManagement -ListAvailable | Select-Object -ExpandProperty Path | Split-Path
C:\Windows\system32\WindowsPowerShell\v1.0\Modules\PrintManagement

PS> explorer (Get-Module -Name PrintManagement -ListAvailable | Select-Object -ExpandProperty Path | Split-Path)
```

这个快速的演练解释了为什么 PowerShell 没有固定的命令集，以及为什么给定命令在一个系统上可用并且在另一个系统上不可用。新模块可以由操作系统（例如 Windows 10 附带的模块多于 Windows 7）、已安装的软件（例如 SQLServer）、已激活的角色（例如域控制器）引入，并且模块也可以手动安装。

例如这行代码从公开的 PowerShell Gallery 中安装一个免费的模块，并且添加了用于创建各种二维码的新命令：

```powershell
PS C:\> Install-Module -Name QRCodeGenerator -Scope CurrentUser -Force
```

一旦模块安装完毕，您会得到类似这样的命令，用来创建 Twitter 用户数据文件的二维码：

```powershell
PS C:\> New-QRCodeTwitter -ProfileName tobiaspsp -Show
```

要查看某个模块中所有命令，请试试这行代码：

```powershell
    PS C:\> Get-Command -Module QRCodeGenerator

    CommandType Name                  Version Source
    ----------- ----                  ------- ------
    Function    New-QRCodeGeolocation 1.2     QRCodeGenerator
    Function    New-QRCodeTwitter     1.2     QRCodeGenerator
    Function    New-QRCodeVCard       1.2     QRCodeGenerator
    Function    New-QRCodeWifiAccess  1.2     QRCodeGenerator
```

<!--本文国际来源：[Exploring PowerShell Modules](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/exploring-powershell-modules-2)-->

