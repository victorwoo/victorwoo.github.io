---
layout: post
date: 2020-03-23 00:00:00
title: "PowerShell 技能连载 - 使用 PSWindowsUpdate 管理更新"
description: PowerTip of the Day - Managing Updates with PSWindowsUpdate
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerShell Gallery 中有许多有用的 PowerShell 模块。有一个能帮助您管理更新。要下载和安装它，请运行：

```powershell
PS> Install-Module -Name PSWindowsUpdate -Scope CurrentUser -Force
```

它添加了一系列与 Windows Update 相关的新命令：

```powershell
PS> Get-Command -Module PSWindowsUpdate

CommandType Name                    Version Source
----------- ----                    ------- ------
Alias       Clear-WUJob             2.1.1.2 PSWindowsUpdate
Alias       Download-WindowsUpdate  2.1.1.2 PSWindowsUpdate
Alias       Get-WUInstall           2.1.1.2 PSWindowsUpdate
Alias       Get-WUList              2.1.1.2 PSWindowsUpdate
Alias       Hide-WindowsUpdate      2.1.1.2 PSWindowsUpdate
Alias       Install-WindowsUpdate   2.1.1.2 PSWindowsUpdate
Alias       Show-WindowsUpdate      2.1.1.2 PSWindowsUpdate
Alias       UnHide-WindowsUpdate    2.1.1.2 PSWindowsUpdate
Alias       Uninstall-WindowsUpdate 2.1.1.2 PSWindowsUpdate
Cmdlet      Add-WUServiceManager    2.1.1.2 PSWindowsUpdate
Cmdlet      Enable-WURemoting       2.1.1.2 PSWindowsUpdate
Cmdlet      Get-WindowsUpdate       2.1.1.2 PSWindowsUpdate
Cmdlet      Get-WUApiVersion        2.1.1.2 PSWindowsUpdate
Cmdlet      Get-WUHistory           2.1.1.2 PSWindowsUpdate
Cmdlet      Get-WUInstallerStatus   2.1.1.2 PSWindowsUpdate
Cmdlet      Get-WUJob               2.1.1.2 PSWindowsUpdate
Cmdlet      Get-WULastResults       2.1.1.2 PSWindowsUpdate
Cmdlet      Get-WURebootStatus      2.1.1.2 PSWindowsUpdate
Cmdlet      Get-WUServiceManager    2.1.1.2 PSWindowsUpdate
Cmdlet      Get-WUSettings          2.1.1.2 PSWindowsUpdate
Cmdlet      Invoke-WUJob            2.1.1.2 PSWindowsUpdate
Cmdlet      Remove-WindowsUpdate    2.1.1.2 PSWindowsUpdate
Cmdlet      Remove-WUServiceManager 2.1.1.2 PSWindowsUpdate
Cmdlet      Set-PSWUSettings        2.1.1.2 PSWindowsUpdate
Cmdlet      Set-WUSettings          2.1.1.2 PSWindowsUpdate
Cmdlet      Update-WUModule         2.1.1.2 PSWindowsUpdate
```

大多数命令需要提升权限的 shell 才能正常工作，但每个人都可以获得基本信息。

```powershell
PS> Get-WULastResults
WARNING: To perform some operations you must run an elevated Windows PowerShell console.

ComputerName    LastSearchSuccessDate LastInstallationSuccessDate
------------    --------------------- ---------------------------
DESKTOP-8DVNI43 22.01.2020 11:29:24   22.01.2020 11:29:52



PS> Get-WUApiVersion
WARNING: To perform some operations you must run an elevated Windows PowerShell console.

ComputerName PSWindowsUpdate PSWUModuleDll   ApiVersion WuapiDllVersion
------------ --------------- -------------   ---------- ---------------
DESKTOP-8... 2.1.1.2         2.0.6995.28496  8.0        10.0.18362.387
```

<!--本文国际来源：[Managing Updates with PSWindowsUpdate](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/managing-updates-with-pswindowsupdate)-->
