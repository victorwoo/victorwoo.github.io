---
layout: post
date: 2023-01-03 00:00:11
title: "PowerShell 技能连载 - Showing Progress in Taskbar Buttons"
description: PowerTip of the Day - Showing Progress in Taskbar Buttons
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您在 Windows 上运行 PowerShell 脚本，则可以将任务栏按钮用作进度指示器。您需要的只是安装此模块：

```powershell
Install-Module -Name PsoProgressButton -Scope CurrentUser
```

接下来，您可以运行下面的命令以将任务栏按钮内的进度栏设置为 0 到 100 之间的值。这段代码将指示器设置为 50％：

```powershell
PS> Set-PsoButtonProgressValue -CurrentValue 50
```

要关闭指示器，请运行以下代码：

```powershell
PS> Set-PsoButtonProgressState -ProgressState NoProgress
```
<!--本文国际来源：[Showing Progress in Taskbar Buttons](https://blog.idera.com/database-tools/powershell/powertips/showing-progress-in-taskbar-buttons/)-->

