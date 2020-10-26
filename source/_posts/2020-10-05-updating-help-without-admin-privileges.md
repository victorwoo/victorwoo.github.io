---
layout: post
date: 2020-10-05 00:00:00
title: "PowerShell 技能连载 - 在没有管理员特权的情况下更新帮助"
description: PowerTip of the Day - Updating Help without Admin Privileges
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 Windows PowerShell 中，由于设计缺陷，更新帮助曾经需要管理员权限：帮助必须存储在模块所在的位置。更新 Windows 文件夹中存储的 Microsoft 模块的帮助需要对 Windows 文件夹的写权限。这就是普通用户无法下载和使用本地 PowerShell 帮助的原因。

在 PowerShell 7 中，此设计缺陷已得到纠正，现在可以将帮助安全地存储在用户配置文件中。不再需要涉及 PowerShell 模块的安装文件夹。

在 PowerShell 7 中使用 `-Verbose` 参数运行 `Update-Help` 以查看更改：

```powershell
PS> Update-Help -Verbose
VERBOSE: Resolving URI: "https://go.microsoft.com/fwlink/?LinkId=717973"
VERBOSE: Your connection has been redirected to the following URI:
"https://pshelpprod.blob.core.windows.net/cabinets/powershell-5.1/"
VERBOSE: Performing the operation "Update-Help" on target "Microsoft.PowerShell.LocalAccounts, Current Version: 5.2.0.0, Available Version: 5.2.0.0, UICulture: en-US".
VERBOSE: Microsoft.PowerShell.LocalAccounts: Updated C:\Users\USERNAME\Dokumente\PowerShell\Help\Microsoft.PowerShell.LocalAccounts\1.0.0.0\en-US\Microsoft.Powershell.LocalAccounts.dll-Help.xml. Culture en-US Version 5.2.0.0
VERBOSE: Resolving URI: "https://go.microsoft.com/fwlink/?linkid=2113632"
VERBOSE: Your connection has been redirected to the following URI: "https://pshelp.blob.core.windows.net/powershell/help/7.0/Microsoft.PowerShell.Management/"
VERBOSE: Performing the operation "Update-Help" on target "Microsoft.PowerShell.Management, Current Version: 7.0.1.0, Available Version: 7.0.1.0, UICulture: en-US".
VERBOSE: Microsoft.PowerShell.Management: Updated C:\Users\USERNAME\Dokumente\PowerShell\Help\en-US\Microsoft.PowerShell.Commands.Management.dll-Help.xml. Culture en-US Version 7.0.1.0
...
```

要使用下载的本地帮助文件，您可以在想了解的命令后添加 "`-?`" 通用参数：

```powershell
PS> Get-Process -?

NAME
    Get-Process

SYNOPSIS
    Gets the processes that are running on the local computer or a remote computer.
...
```

如果您之前未下载本地帮助文件，则 "-" 参数仅显示有限的语法帮助。

<!--本文国际来源：[Updating Help without Admin Privileges](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/updating-help-without-admin-privileges)-->

