---
layout: post
date: 2023-08-14 08:00:53
title: "PowerShell 技能连载 - Windows 系统的温度控制"
description: PowerTip of the Day - Temperature Control for Windows Systems
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Windows 笔记本电脑（以及服务器）可能会变得很热，尤其是在夏天。令人惊讶的是，在 Windows 中没有简单的内置方法来监控温度传感器。了解机器有多热实际上非常重要，可以改善操作条件等方面带来巨大好处。例如，将笔记本电脑抬起并允许足够的空气进入通风口对它们非常有益。

这里有一个 PowerShell 模块，使温度监控变得非常简单：

```powershell
PS> Install-Module -Name PSTemperatureMonitor
```

要从PowerShell Gallery安装此模块，您需要本地管理员权限，这是有道理的，因为无论如何您都需要本地管理员权限来读取硬件状态。

安装完模块后，请使用管理员权限启动PowerShell，然后启动温度监控，即每5秒刷新一次。

```powershell
PS> Start-MonitorTemperature -Interval 5 | Format-Table -Wrap
WARNING: HardwareMonitor opened.

Time     CPU Core #1 CPU Core #2 CPU Core #3 CPU Core #4 CPU Package HDD Temperature Average
----     ----------- ----------- ----------- ----------- ----------- --------------- -------
12:17:31          65          69          66          65          69              53      64
12:17:36          63          62          63          59          62              53      60
12:17:41          62          59          59          59          62              53      59
12:17:46          61          62          62          58          62              53      60
12:17:51          70          68          63          63          70              53      64
12:17:56          59          60          55          56          61              53      57
12:18:02          60          60          57          61          61              53      59
12:18:07          65          68          61          62          68              53      63
WARNING: HardwareMonitor closed.
```

按下 CTRL+C 中止监控。更多详细信息请访问此处：https://github.com/TobiasPSP/PSTemperatureMonitor
<!--本文国际来源：[Temperature Control for Windows Systems](https://blog.idera.com/database-tools/powershell/powertips/temperature-control-for-windows-systems/)-->

