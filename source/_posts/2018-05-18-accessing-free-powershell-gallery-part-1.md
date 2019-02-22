---
layout: post
date: 2018-05-18 00:00:00
title: "PowerShell 技能连载 - 使用免费的 PowerShell 陈列架（第 1 部分）"
description: PowerTip of the Day - Accessing Free PowerShell Gallery (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 是一个可扩展的框架，并且 PowerShell 陈列架 ([www.powershellgallery.com](http://www.powershellgallery.com)) 上有许多免费和有用的命令扩展。我们将在几个技能帖子中介绍这个陈列架的巨大功能。

要从 PowerShellGallery 中下载和安装任何扩展，您需要 PowerShellGet 模块，它提供了许多用于浏览、下载、安装、更新，和移除扩展的命令。

PowerShellGet 模块随着 PowerShell 5 分发，这是确认是否有该模块权限的方法：

```powershell
PS> Get-Module PowerShellGet -ListAvailable


    Directory: C:\Program Files\WindowsPowerShell\Modules


ModuleType Version    Name                                ExportedCommands
---------- -------    ----                                ----------------
Script     1.0.0.1    PowerShellGet                       {Install-Module, Find-...
```

当您运行 PowerShell 5 时，您可能需要确认是否使用的是最终的版本。上一条命令汇报了已安装的版本。要检查陈列架中最新可用的版本，请试试这段代码：

```powershell
PS> Find-Module PowerShellGet

Version    Name                                Repository           Description
-------    ----                                ----------           -----------
1.6.0      PowerShellGet                       PSGallery            PowerShell...
```

要更新之前通过 PowerShell 陈列架安装的任意模块，您只需要运行 `Update-Module`，不过它对 PowerShellGet 运行失败：

```powershell
PS> Update-Module PowerShellGet
Update-Module : Module 'PowerShellGet' was not installed by using Install-Module, so it cannot be updated.
```

这是因为该模块是随着 Windows 10 分发，您需要手工重新安装该模块。如果您有管理员权限，强烈建议先打开一个提升权限的 PowerShell，然后基于它安装（更新）以下的包：

```powershell
PS> Install-PackageProvider Nuget –Force

Name                           Version          Source           Summary
----                           -------          ------           -------
nuget                          2.8.5.208        https://onege... N...
```

如果您没有事先更新包管理器，您坑无法更新 PowerShellGet 模块。当您更新了包管理器之后，请关闭所有 PowerShell 窗口，并打开一个全新的 PowerShell 控制台，以确保它使用新的包管理器。

下一步，安装最新版本的 PowerShellGet：

```powershell
PS> Install-Module –Name PowerShellGet –Force
```

如果您没有管理员权限，那么用 `-Scope CurrentUser` 参数只为当前用户安装 PowerShellGet。

您现在可以在已有版本之外独立使用最新本的 PowerShellGet：

```powershell
PS> Get-Module PowerShellGet -ListAvailable


    Directory: C:\Program Files\WindowsPowerShell\Modules


ModuleType Version    Name                                ExportedCommands
---------- -------    ----                                ----------------
Script     1.6.0      PowerShellGet                       {Install-Module, Find-Module...
Script     1.0.0.1    PowerShellGet                       {Install-Module, Find-Module...
```

您现在可以完美地通过 `Update-Module`（使用您安装它时相同的权限）更新模块：

```powershell
PS> Update-Module PowerShellGet
```

这下您的指尖又多列一些命令：

```powershell
PS> Get-Command -Module PowerShellGet

CommandType     Name                                               Version    Sou
                                                                                rce
-----------     ----                                               -------    ---
Function        Find-Command                                       1.6.0      Pow
Function        Find-DscResource                                   1.6.0      Pow
Function        Find-Module                                        1.6.0      Pow
Function        Find-RoleCapability                                1.6.0      Pow
Function        Find-Script                                        1.6.0      Pow
Function        Get-InstalledModule                                1.6.0      Pow
Function        Get-InstalledScript                                1.6.0      Pow
Function        Get-PSRepository                                   1.6.0      Pow
Function        Install-Module                                     1.6.0      Pow
Function        Install-Script                                     1.6.0      Pow
Function        New-ScriptFileInfo                                 1.6.0      Pow
Function        Publish-Module                                     1.6.0      Pow
Function        Publish-Script                                     1.6.0      Pow
Function        Register-PSRepository                              1.6.0      Pow
Function        Save-Module                                        1.6.0      Pow
Function        Save-Script                                        1.6.0      Pow
Function        Set-PSRepository                                   1.6.0      Pow
Function        Test-ScriptFileInfo                                1.6.0      Pow
...
```

<!--本文国际来源：[Accessing Free PowerShell Gallery (Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/accessing-free-powershell-gallery-part-1)-->
