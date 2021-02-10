---
layout: post
date: 2021-02-10 00:00:00
title: "PowerShell 技能连载 - 在 Windows 上安装 PowerShell 7 的最简单方法"
description: PowerTip of the Day - Simplest Way to Install PowerShell 7 on Windows
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
为 Windows 用户下载和安装 PowerShell 7 的最简单，最灵活的方法可能是运行以下单行代码：

```powershell
Invoke-RestMethod -Uri https://aka.ms/install-powershell.ps1 | New-Item -Path function: -Name Install-PowerShell | Out-Null
```

它创建了一个拥有许多参数的 cmdlet `Install-PowerShell`。例如，要将 Windows 7 的最新生产版本作为便携式应用程序下载到您选择的文件夹中，请运行以下命令：

```powershell
Install-PowerShell -Destination c:\ps7test -AddToPath
```

如果您希望以托管的 MSI 应用程序的形式安装 PowerShell 7，请运行以下命令：

```powershell
Install-PowerShell -UseMSI -Quiet
```

注意：真正安静的安装需要管理员权限。

<!--本文国际来源：[Simplest Way to Install PowerShell 7 on Windows](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/simplest-way-to-install-powershell-7-on-windows)-->

