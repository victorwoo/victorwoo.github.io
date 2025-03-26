---
layout: post
date: 2023-07-25 08:00:18
title: "PowerShell 技能连载 - 自动化控制面板"
description: PowerTip of the Day - Automating Control Panels
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Windows 控制面板是系统配置的图形用户界面中心。你也可以通过控制台命令来启动控制面板：输入 `control [ENTER]`。然而，即使 PowerShell 也支持控制面板：

`Get-ControlPanelItem` 列出所有可用的控制面板项目，你可以通过名称或描述来搜索控制面板项目。以下命令可以找到与 "print" 相关的控制面板项目：

```powershell
PS> Get-ControlPanelItem -Name *print*

Name                 CanonicalName                Category             Description
----                 -------------                --------             -----------
Devices and Printers Microsoft.DevicesAndPrinters {Hardware and Sound} View and manage devices, printers, and print jobs
```

`Show-ControlPanelItem` 可以用来打开一个或多个控制面板项目。请注意，这些 cmdlet 不能自动化设置更改，但它们可以帮助快速识别和打开基于 GUI 的控制面板项目。与其花费多次点击来打开控制面板并找到适当的控制面板项目进行管理（比如本地打印机），您也可以使用 PowerShell 控制台并输入以下命令：

```powershell
PS> Show-ControlPanelItem -Name *print*
```

注意：`*-ControlPanelItem` cmdlets 仅在 Windows PowerShell 中可用。
<!--本文国际来源：[Automating Control Panels](https://blog.idera.com/database-tools/powershell/powertips/automating-control-panels/)-->

