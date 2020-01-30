---
layout: post
date: 2020-01-23 00:00:00
title: "PowerShell 技能连载 - 安装 ActiveDirectory 模块"
description: PowerTip of the Day - Installing ActiveDirectory Module
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
这是一个对所有处理 Active Directory 的 PowerShell 用户的好消息：在最新的 Windows 10 版本（企业版、专业版）中，Microsoft 提供了 RSAT 工具，因此不需要另外下载。要将使用 AD 的 PowerShell 命令，只需启用 RSAT 功能（请参见下文）。

此外，PowerShell 7 终于原生支持 Active Directory 模块！如果您开始将新的 PowerShell 与Windows PowerShell 并行使用，则现在可以在 PowerShell 7 中使用以前仅在 Windows PowerShell 中工作的所有 AD cmdlet。

在提升权限的 PowerShell 中运行此命令，以查看可用的 RSAT 组件：

```powershell
Get-WindowsCapability -Online |
    Where-Object Name -like Rsat*
```

要使用 Active Directory 和组策略 PowerShell 模块，请启用 RSAT 功能

```powershell
Get-WindowsCapability -Online |
    Where-Object Name -like Rsat* |
    Where-Object State -ne Installed |
    Add-WindowsCapability -Online
```

完成后，Windows PowerShell 中将同时提供 `Active Directory` 和 `GroupPolicy` PowerShell 模块。在 PowerShell 7 中，只能使用 `ActiveDirectory` 模块。

```powershell
PS> Get-Module -Name ActiveDirectory, GroupPolicy -ListAvailable


    Directory: C:\Windows\system32\WindowsPowerShell\v1.0\Modules


ModuleType Version Name            ExportedCommands
---------- ------- ----            ----------------
Manifest   1.0.1.0 ActiveDirectory {Add-ADCentralAccessPolicyMember, Add-ADCom...
Manifest   1.0.0.0 GroupPolicy     {Backup-GPO, Block-GPInheritance, Copy-GPO...
```

<!--本文国际来源：[Installing ActiveDirectory Module](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/installing-activedirectory-module)-->

