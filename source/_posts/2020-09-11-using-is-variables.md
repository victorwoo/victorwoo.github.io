---
layout: post
date: 2020-09-11 00:00:00
title: "PowerShell 技能连载 - 使用 $Is* 变量"
description: PowerTip of the Day - Using $Is* Variables
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在PowerShell 7 中，有一组新的变量都以 "Is" 开头。它们可帮助您了解脚本运行的环境：

```powershell
PS> Get-Variable -Name is*
Name                           Value
----                           -----
IsCoreCLR                      True
IsLinux                        False
IsMacOS                        False
IsWindows                      True
```

在 Windows 附带的 Windows PowerShell 中，这些变量尚不存在。这是可以理解的，因为 Windows PowerShell 是 Windows 的一部分，而且无论如何都不能跨平台兼容。

要在Windows（或任何其他受支持的平台）上运行PowerShell 7，请访问发布页面[https://github.com/PowerShell/PowerShell/releases](https://github.com/PowerShell/PowerShell/releases) ，向下滚动到 "Assets" 标题，然后下载最适合您的安装软件包。

在 Windows PowerShell中，只需运行以下代码即可：

```powershell
iex "& { $(irm https://aka.ms/install-powershell.ps1) } -UseMSI"
```

要启动 PowerShell 7，请运行 `pwsh.exe`。

<!--本文国际来源：[Using $Is* Variables](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-is-variables)-->

