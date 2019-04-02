---
layout: post
date: 2019-03-29 00:00:00
title: "PowerShell 技能连载 - 修复 PowerShell 上下文菜单"
description: PowerTip of the Day - Repairing PowerShell Context Menus
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您在文件管理器中右键点击一个 PowerShell 脚本文件时，通常会见到一个名为“使用 PowerShell 运行”的上下文菜单项，可以通过它快速地执行 PowerShell 脚本。

然而，在某些系统中，“使用 PowerShell 运行“命令缺失了。原因是当您定义了一个非缺省的“打开方式”命令，那么该命令就会隐藏。要修复它，您只需要删除这个注册表键：

```powershell
HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.ps1\UserChoice
```

在 regedit.exe 中删除这个键很简单，而且当这个键移除之后，“使用 PowerShell 运行”上下文菜单就再次可见了。

不过实际中在 PowerShell 删除这个注册表键却不太容易。以下这些命令执行都会失败，报告某些子项无法删除：

```powershell
PS C:\> Remove-Item HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.ps1\UserChoice

PS C:\> Remove-Item Registry::HKEY:CURRENT_USER:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.ps1\UserChoice

PS C:\> Remove-Item 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.ps1\UserChoice'

PS C:\> Remove-Item HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\'.ps1'\UserChoice

PS C:\> Remove-Item HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.ps1\UserChoice -Recurse -Force
```

我们明天会提供一个解决方案来应对这种情况。

<!--本文国际来源：[Repairing PowerShell Context Menus](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/repairing-powershell-context-menus)-->

