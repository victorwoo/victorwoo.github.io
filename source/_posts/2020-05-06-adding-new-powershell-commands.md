---
layout: post
date: 2020-05-06 00:00:00
title: "PowerShell 技能连载 - 增加新的 PowerShell 命令"
description: PowerTip of the Day - Adding New PowerShell Commands
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 只是一个脚本平台，可以增加新命令来扩展。新命令的一个很好的来源是公开的 PowerShell Gallery。您可以访问 [https://powershellgallery.com]（https://powershellgallery.com）上的图形前端，并搜索模块。

PowerShell 带有一个称为 `PowerShellGet` 的模块，该模块又提供了从 PowerShell 库下载和安装扩展的命令。我们现在就下载并安装免费的命令扩展程序。

当前最受欢迎的通用 PowerShell 命令扩展之一是免费的 Carbon 模块，在过去六周中下载了将近 400 万次。要从 PowerShell 库中安装它，请使用 `Install-Module`。使用 CurrentUser 范围时，不需要管理员权限：

```powershell
PS> Install-Module -Name Carbon -Scope CurrentUser
```

首次使用时，`Install-Module` 会请求下载许可并使用 "`nuget`" DLL，该 DLL 负责下载和安装过程。接下来，下载并解压缩请求的模块。由于 PowerShell 库是一个公共存储库，因此要求您同意将材料下载到计算机上。使用 `-Force` 参数可以跳过此部分。

重要提示：PowerShell Gallery 提供的大多数 PowerShell 模块都是基于脚本的。您需要允许执行脚本；否则，您将无法使用基于脚本的模块。如果尚未允许脚本执行，则可以使用以下命令：

```powershell
PS> Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
```

要查看新的 PowerShell 命令，请列出添加的模块中包含的命令：

```powershell
PS> Get-Command -Module Carbon | Out-GridView
```

这是一个例子：

```powershell
PS> Get-FileShare

Name   Path                              Description
----   ----                              -----------
ADMIN$ C:\Windows                        Remote Admin
C$     C:\                               Default share
print$ C:\Windows\system32\spool\drivers PrintDrivers
```

<!--本文国际来源：[Adding New PowerShell Commands](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/adding-new-powershell-commands)-->

