---
layout: post
date: 2018-04-09 00:00:00
title: "PowerShell 技能连载 - 用 Chocolatey 安装 PowerShell 6"
description: PowerTip of the Day - Installing PowerShell 6 with Chocolatey
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在之前的技能中，我们解释了如何下载和安装 Chocolatey，一个免费的 Windows 包管理器，可以用来安装软件。

今天，我们将看看如何用 Chocolatey 下载 PowerShell Core 6，这样您就可以体验它了。该安装并不会改变当前的 PowerShell 版本，所以您可以安全地同时安装它。

要安装 PowerShell Core 包，您需要管理员权限。用完整管理员权限打开一个 PowerShell 窗口。请不要用 PowerShell ISE 打开 Chocolatey，因为 PowerShell ISE 无法显示交互式控制台信息和提示。

如果您将 chocolatey 安装为一个便携式软件，请将它的路径添加到 Windows 的 `Path` 环境变量中。然后运行安装命令：

```powershell
PS> $env:path += ";C:\ProgramData\chocoportable"

PS> choco install powershell-core -y
```

当 Choco 确定依赖关系、下载和安装必备项时，您将会见到一系列信息，最后才是安装 PowerShell Core 6。

当安装完成时，PowerShell Core 6 可以在 `C:\Program Files\PowerShell\[Version]\pwsh.exe` 这儿找到。

要确认您通过 Chocolatey 安装的包是否过时，请运行这条命令：

```powershell
PS> choco outdated
```

如果需要更新一个已安装的包，请使用这条命令：

    powershell
    PS C:\> choco upgrade powershell-core
    Chocolatey v0.10.8
    Upgrading the following packages:
    powershell-core
    By upgrading you accept licenses for the packages.
    powershell-core v6.0.2 is the latest version available based on your source(s).

    Chocolatey upgraded 0/1 packages.
    See the log for details (C:\ProgramData\chocoportable\logs\chocolatey.log).
    PS C:\>

<!--本文国际来源：[Installing PowerShell 6 with Chocolatey](http://community.idera.com/powershell/powertips/b/tips/posts/installing-powershell-6-with-chocolatey)-->
