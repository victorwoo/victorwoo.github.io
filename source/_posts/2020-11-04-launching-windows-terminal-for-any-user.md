---
layout: post
date: 2020-11-04 00:00:00
title: "PowerShell 技能连载 - 为任何用户启动 Windows 终端"
description: PowerTip of the Day - Launching Windows Terminal for Any User
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 Windows 10 上，任何 PowerShell 用户都可以使用一个很棒的新工具：Windows Terminal。它使您可以同时使用多个 PowerShell 和其他控制台选项卡，并且可以混合使用 Windows PowerShell、PowerShell 7 和 Azure Cloud Shell 控制台。您可以从 Microsoft Store 安装Windows Terminal。

由于 Windows Terminal 是一个“应用程序”，因此始终以为每个用户独立安装。只有事先为该用户安装了该应用程序，才可以通过其可执行文件 wt.exe 启动它。

启动 Windows Terminal 的另一种方法是以下命令：

```cmd
start shell:appsFolder\Microsoft.WindowsTerminal_8wekyb3d8bbwe!App
```

如果此调用不能帮助您从其他用户帐户启动 Windows Terminal，那么在即将发布的技能中，我们将介绍如何将应用程序转变为不再由 Windows 管理的便携式应用程序。取而代之的是，您可以用任何用户（包括高级帐户）运行它。敬请关注。

<!--本文国际来源：[Launching Windows Terminal for Any User](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/launching-windows-terminal-for-any-user)-->

