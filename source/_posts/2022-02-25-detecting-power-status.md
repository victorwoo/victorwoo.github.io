---
layout: post
date: 2022-02-25 00:00:00
title: "PowerShell 技能连载 - 检测电源状态"
description: PowerTip of the Day - Detecting Power Status
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
虽然很难直接访问 Windows 电源管理 API，但还有其他 API 可以实现相同需求。以下代码返回您机器的当前电源状态。如果您使用的是笔记本电脑并且没有交流电源，它可以告诉您剩余电池电量：

```powershell
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.SystemInformation]::PowerStatus
```

结果类似这样：

    PowerLineStatus      : Offline
    BatteryChargeStatus  : 0
    BatteryFullLifetime  : -1
    BatteryLifePercent   : 0,45
    BatteryLifeRemaining : 13498

<!--本文国际来源：[Detecting Power Status](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/detecting-power-status)-->

