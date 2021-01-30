---
layout: post
date: 2020-12-16 00:00:00
title: "PowerShell 技能连载 - 保持 Windows 和 PowerShell 持续运行"
description: PowerTip of the Day - Keeping Windows (and PowerShell) Running
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
根据 Windows PC 的电源设置，即使您在运行冗长的脚本，您的计算机仍可能在一段时间后进入待机或休眠状态。

确保 Windows 在脚本忙时继续运行的一种方法是使用“演示模式”。您可以使用一个工具来启用和禁用它。在 PowerShell 中，运行以下命令：

```powershell
PS> presentationsettings
```

这将打开一个窗口，您可以在其中检查和控制当前的演示文稿设置。要自动启动和停止演示模式，该命令支持参数 `/start` 和 `/stop`。

为了确保 Windows 在脚本运行时不会进入休眠状态，请将其放在第一行脚本中：

```powershell
PS> presentationsettings /start
```

在脚本末尾，关闭演示模式，如下所示：

```powershell
PS> presentationsettings /stop
```

要验证这两个命令的效果，请运行不带参数的命令，并选中对话框中最上方的复选框。

<!--本文国际来源：[Keeping Windows (and PowerShell) Running](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/keeping-windows-and-powershell-running)-->

