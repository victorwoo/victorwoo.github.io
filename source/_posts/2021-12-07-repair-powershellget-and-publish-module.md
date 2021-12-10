---
layout: post
date: 2021-12-07 00:00:00
title: "PowerShell 技能连载 - 修复 PowerShellGet 和 Publish-Module"
description: PowerTip of the Day - Repair PowerShellGet and Publish-Module
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`Publish-Module` 是一个 cmdlet，用于将模块发布（上传）到 NuGet 仓库。有时，此 cmdlet 会引发奇怪的异常。这种情况下的原因是 nuget.exe 的过时版本。该应用程序负责打包一个模块并保存为.nupkg 文件，并且在您第一次使用 `Publish-Module` 时会自动下载该应用程序。

要更正此问题并刷新您的 nuget.exe 版本，请运行以下命令：

```powershell
Invoke-WebRequest -Uri https://dist.nuget.org/win-x86-commandline/latest/nuget.exe -OutFile "$env:LOCALAPPDATA\Microsoft\Windows\PowerShell\PowerShellGet\NuGet.exe"
```

确保在此之后关闭并重新启动所有 PowerShell 会话。如果 `Publish-Module` 仍然拒绝工作，您可能需要运行以下命令（需要管理员权限）：

```powershell
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
```

<!--本文国际来源：[Repair PowerShellGet and Publish-Module](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/repair-powershellget-and-publish-module)-->

