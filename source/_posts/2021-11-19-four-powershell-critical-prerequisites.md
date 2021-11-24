---
layout: post
date: 2021-11-19 00:00:00
title: "PowerShell 技能连载 - 四个 PowerShell 关键先决条件"
description: PowerTip of the Day - Four PowerShell Critical Prerequisites
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您要切换到新计算机，您可能需要快速检查一下 PowerShell 是否设置正确。以下是您绝对应该检查的四件事：

## 1 检查 PowerShell 版本

运行 `$PSVersionTable` 以检查您的 PowerShell 版本。

```powershell
PS> $PSVersionTable

Name                           Value
----                           -----
PSVersion                      5.1.19041.1237
PSEdition                      Desktop
PSCompatibleVersions           {1.0, 2.0, 3.0, 4.0...}
BuildVersion                   10.0.19041.1237
CLRVersion                     4.0.30319.42000
WSManStackVersion              3.0
PSRemotingProtocolVersion      2.3
SerializationVersion           1.1.0.1
```

由于 `$PSVersionTable` 是一个哈希表，您还可以将其转换为对象以选择某些属性：

```
PS> [PSCustomObject]$PSVersionTable | Select-Object -Property PSVersion, PSEdition

PSVersion      PSEdition
---------      ---------
5.1.19041.1237 Desktop
```

如果 "`PSEdition`" 是 "`Desktop`"，则您使用的是内置的 Windows PowerShell。应该是 5.1 版。任何旧版本均已弃用，使用旧版本可能会引发安全风险。由于 Windows PowerShell 功能齐全，因此没有超过 5.1 的新版本。

如果 "`PSEdition`" 是 "`Core`"，那么您使用的是新的跨平台 PowerShell。当前版本为 7.1.5，更新频繁。

## 2 检查运行策略

如果你不能运行脚本，PowerShell 就没有意义了。执行策略应设置为 "`RemoteSigned`"（仅允许本地脚本）或 "`Bypass`"（位于任何地方的脚本都可以运行，包括下载的脚本）：

```powershell
PS> Get-ExecutionPolicy
Bypass
```

如果需要，使用以下代码来更改执行策略：

```powershell
PS> Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
```

## 3 检查 PowerShellGet

`PowerShellGet` 是一个重要的附加组件，因为它代表了 PowerShell 包管理。使用 `PowerShellGet`，您可以通过 `Install-Module` 安装其他模块。如果此模块已过时，您可能无法再下载和安装其他模块：

```powershell
PS> Get-Module -Name PowerShellGet -ListAvailable | Sort-Object -Property Version -Descending | Select-Object -First 1 -Property Version

Version
-------
2.2.5
```

如果报告的版本低于 2.2.0，则需要更新此模块。如果您看到版本 1.0.0 或 1.0.1（最初随 Windows 一起提供并且此后从未更新过的初始模块），则尤其如此。

要更新该模块，您需要重新安装它及其必备的 PackageManagement 模块：

```powershell
Install-Module -Name PowerShellGet -Scope CurrentUser -Force -AllowClobber
Install-Module -Name Packagemanagement -Scope CurrentUser -Force -AllowClobber
```

## TLS 1.2 支持

最后要检查的是 Windows 是否设置为支持传输层协议 1.2：

```powershell
PS> ([System.Net.ServicePointManager]::SecurityProtocol -band 'Tls12') -eq 'Tls12'
True
```

If this is $false, then your Windows still uses outdated settings, and PowerShell may not be able to connect to HTTPS: webservices and sites. You should update Windows. Meanwhile, you can manually enable TLS 1.2 on a per-application setting:
如果返回 `$false`，那么您的 Windows 仍然使用过时的设置，并且 PowerShell 可能无法连接到 HTTPS：网络服务和网站。您应该更新 Windows。同时，您可以在每个应用程序独立的设置上手动启用 TLS 1.2：

```powershell
[System.Net.ServicePointManager]::SecurityProtocol =
[System.Net.ServicePointManager]::SecurityProtocol -bor
[System.Net.SecurityProtocolType]::Tls12
```

<!--本文国际来源：[Four PowerShell Critical Prerequisites](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/four-powershell-critical-prerequisites)-->

