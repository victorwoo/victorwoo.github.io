---
layout: post
date: 2023-01-09 00:00:25
title: "PowerShell 技能连载 - 在任务栏按钮显示错误状态"
description: PowerTip of the Day - Showing Error State in Taskbar Button
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您的脚本执行时发生错误，如果能通过任务栏按钮显示错误状态，那么是再好不过的了。如果一个任务栏按钮显示红色，您可以立即知道该关注您的脚本。

您所需的只是这个模块：

```powershell
Install-Module -Name PsoProgressButton -Scope CurrentUser
```

然后，设置一个进度值并且将它设置为红色：

```powershell
Set-PsoButtonProgressState -ProgressState Error
Set-PsoButtonProgressValue -CurrentValue 100
```

要关闭指示，请运行以下代码：

```powershell
PS> Set-PsoButtonProgressState -ProgressState NoProgress
```
<!--本文国际来源：[Showing Error State in Taskbar Button](https://blog.idera.com/database-tools/powershell/powertips/showing-error-state-in-taskbar-button/)-->

