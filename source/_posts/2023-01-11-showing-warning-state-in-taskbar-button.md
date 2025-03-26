---
layout: post
date: 2023-01-11 06:00:20
title: "PowerShell 技能连载 - 在任务栏按钮显示警告状态"
description: PowerTip of the Day - Showing Warning State in Taskbar Button
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您的脚本需要注意，例如需要用户输入时，我们可以将 Windows 任务栏中的按钮变为橙色，这样用户可以立即知道需要检查您的脚本。

您所需的只是这个模块：

```powershell
Install-Module -Name PsoProgressButton -Scope CurrentUser
```

下一步，设置一个进度值并且将它设置成红色：

```powershell
Set-PsoButtonProgressState -ProgressState Paused
Set-PsoButtonProgressValue -CurrentValue 100
```

要关闭指示，请运行以下脚本：

```powershell
PS> Set-PsoButtonProgressState -ProgressState NoProgress
```
<!--本文国际来源：[Showing Warning State in Taskbar Button](https://blog.idera.com/database-tools/powershell/powertips/showing-warning-state-in-taskbar-button/)-->

