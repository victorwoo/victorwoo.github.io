---
layout: post
date: 2020-04-10 00:00:00
title: "PowerShell 技能连载 - 允许 PowerPoint 中的点击操作"
description: PowerTip of the Day - Enabling Clickable PowerPoint Actions
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerPoint 演示文稿中使用点击操作对于启动 Visual Studio Code 或 PowerShell ISE 以及无缝打开和演示 PowerShell 代码非常有用。

但是，出于安全原因，默认情况下禁止通过插入的“操作”项启动程序，并且没有启用它的简便方法。而且，即使您确实启用了此功能，PowerPoint 也会在短时间后将其恢复为保护模式。

这是一个快速的 PowerShell脚本，您可以在演示之前立即运行它，以确保所有可点击的“操作”点击后能生效。

```powershell
$path = 'HKCU:\Software\Microsoft\Office\16.0\PowerPoint\Security'
Set-ItemProperty -Path $path -Name RunPrograms -Value 1 -Type DWord
```

<!--本文国际来源：[Enabling Clickable PowerPoint Actions](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/enabling-clickable-powerpoint-actions)-->

