---
layout: post
date: 2019-05-30 00:00:00
title: "PowerShell 技能连载 - 内置的 RSAT 工具"
description: PowerTip of the Day - RSAT Tools Built-In
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
远程服务器管理工具 (RSAT) 过去是一个外部下载，添加了两个重要的 PowerShell 模块：`ActiveDirectory` 和 `GroupPolicy`。不幸的是，主要的 Windows 更新移除了已安装的 RSAT 工具，所以如果您的脚本需要客户端的 Active Dicrectory 命令，那么需要人工确定并且下载合适新版 Windows 10 的 RSAT 包并且手工安装它。

在 Windows 10 Build 1809 和以后的版本中，这要更容易一些。您可以通过 PowerShell 以类似这样的方式控制 RSAT 状态（假设您有管理员特权）：

```powershell
PS> Get-WindowsCapability -Online -Name *RSAT.ActiveDirectory*


Name         : Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
State        : NotPresent
DisplayName  : RSAT: Active Directory Domain Services and Lightweight Directory Services Tools
Description  : Active Directory Domain Services (AD DS) and Active Directory Lightweight Directory Services (AD LDS) Tools include snap-ins and command-line tools for remotely managing AD DS and AD LDS on Windows Server.
DownloadSize : 5230337
InstallSize  : 17043386
```

要安装 RSAT，请运行以下代码：

```powershell
PS> Get-WindowsCapability -Online -Name *RSAT.ActiveDirectory* |
    Add-WindowsCapability -Online


Path          :
Online        : True
RestartNeeded : False




PS> Get-Module -Name ActiveDirectory -ListAvailable


    Directory: C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules


ModuleType Version    Name                                ExportedCommands
---------- -------    ----                                ----------------
Manifest   1.0.1.0    ActiveDirectory                     {Add-...
```

虽然在某些情况下仍然需要下载 RSAT 包，但您不再需要搜索正确的版本并手动构建。

<!--本文国际来源：[RSAT Tools Built-In](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/rsat-tools-built-in)-->

