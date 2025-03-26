---
layout: post
date: 2023-01-05 06:00:41
title: "PowerShell 技能连载 - 在任务栏按钮中显示不确定的进度"
description: PowerTip of the Day - Showing Indeterminate Progress in Taskbar Buttons
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有时，您不知道脚本的确切进度，但您仍然想通知用户您的脚本“忙”。如果您在 Windows 上运行 PowerShell 脚本，则可以使用任务栏按钮显示不确定的进度条。该进度条将“永远”运行，直到您将其关闭。

您需要的只是安装此模块：

```powershell
Install-Module -Name PsoProgressButton -Scope CurrentUser
```

接下来，您可以运行下面的命令以打开不确定的进度条。它在代表您的运行 PowerShell 脚本的任务栏按钮内显示：

```powershell
PS> Set-PsoButtonProgressState -ProgressState Indeterminate
```

要关闭该指示器，请运行以下操作：

```powershell
PS> Set-PsoButtonProgressState -ProgressState NoProgress
```
<!--本文国际来源：[Showing Indeterminate Progress in Taskbar Buttons](https://blog.idera.com/database-tools/powershell/powertips/showing-indeterminate-progress-in-taskbar-buttons/)-->

