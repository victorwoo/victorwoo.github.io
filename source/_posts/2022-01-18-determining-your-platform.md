---
layout: post
date: 2022-01-18 00:00:00
title: "PowerShell 技能连载 - 决定您的平台"
description: PowerTip of the Day - Determining Your Platform
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
现在的 PowerShell 已是跨平台的，因此即使能在 Windows 服务器上正常使用 Windows PowerShell，您的脚本也有可能在不同的操作系统上停止运行。

如果您的脚本想要知道它正在运行的平台，以向后兼容的方式运行，请尝试这些代码：

```powershell
$RunOnWindows = (-not (Get-Variable -Name IsWindows -ErrorAction Ignore)) -or $IsWindows
$RunOnLinux = (Get-Variable -Name IsLinux -ErrorAction Ignore) -and $IsLinux
$RunOnMacOS = (Get-Variable -Name IsMacOS -ErrorAction Ignore) -and $IsMacOS

Get-Variable -Name RunOn*
```

在 Windows 系统上，结果如下所示：

    Name                           Value
    ----                           -----
    RunOnLinux                     False
    RunOnMacOS                     False
    RunOnWindows                   True

您现在可以安全地检查先决条件，并确保您的脚本代码仅在适当的情况下运行。

<!--本文国际来源：[Determining Your Platform](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/determining-your-platform)-->

