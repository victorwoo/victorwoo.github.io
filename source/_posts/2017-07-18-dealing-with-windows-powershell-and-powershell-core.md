---
layout: post
date: 2017-07-18 00:00:00
title: "PowerShell 技能连载 - 探讨 Windows PowerShell 和 PowerShell Core"
description: "PowerTip of the Day - Dealing with “Windows PowerShell” and “PowerShell Core”"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
PowerShell 当前有两个版本：随 Windows 发布、基于完整 .NET 框架的的 "Windows PowerShell"，以及基于 .NET Core、支持跨平台、能够运行在 Nano Server 等平台的 "PowerShell Core"。

面向某个具体 PowerShell 版本的脚本作者可以使用 `#requires` 语句来确保他们的脚本运行于指定的版本。

例如，要确保一个脚本运行于 PowerShell Core 中，请将这段代码放在脚本顶部：

```powershell
#requires -PSEdition Core
Get-Process
```

请确保把这段代码保存到磁盘。`#requires` 只对脚本有效。

当您在 Windows 机器上的 "Windows PowerShell" 中运行这段脚本，将会报错：

```powershell
PS> C:\Users\abc\requires  core.ps1
The script 'requires  core.ps1' cannot be run because it contained a "#requires" statement  for PowerShell
editions 'Core'. The  edition of PowerShell that is required by the script does not match the  currently
running PowerShell  Desktop edition.
    + CategoryInfo          : NotSpecified: (requires  core.ps1:String) [], ParentContainsErrorRecordException
    + FullyQualifiedErrorId :  ScriptRequiresUnmatchedPSEdition


PS>
```

类似地，甚至更重要的是，当您将 "Core" 替换为 "Desktop"，脚本将无法在受限的 "PowerShell Core" 版本中运行。如果您的脚本依赖于传统 Windows 系统中的某些特性，并且依赖于完整 .NET Framework，这种做法十分明智。

<!--more-->
本文国际来源：[Dealing with “Windows PowerShell” and “PowerShell Core”](http://community.idera.com/powershell/powertips/b/tips/posts/dealing-with-windows-powershell-and-powershell-core)
