---
layout: post
date: 2023-02-08 06:00:34
title: "PowerShell 技能连载 - 检测电池健康与质量"
description: PowerTip of the Day - Checking Battery Wear and Quality
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您在使用笔记本电脑，那么可以轻松地询问 WMI 得到电池的状态，例如充电状态。如果多做一点功课，您还可以检查电池的健康并且了解是否该更换电池。

本质上，下面的脚本使用不同的 WMI 类来确定电池的标称容量和实际容量，然后以百分比计算其有效容量。任何低于 80% 的百分比通常表明高度损耗和需要更换电池。

```powershell
$designCap = Get-WmiObject -Class "BatteryStaticData" -Namespace "ROOT\WMI" |
Group-Object -Property InstanceName -AsHashTable -AsString

Get-CimInstance -Class "BatteryFullChargedCapacity" -Namespace "ROOT\WMI" |
Select-Object -Property InstanceName, FullChargedCapacity, DesignedCapacity, Percent |
ForEach-Object {
    $_.DesignedCapacity = $designCap[$_.InstanceName].DesignedCapacity
    $_.Percent = [Math]::Round( ( $_.FullChargedCapacity*100/$_.DesignedCapacity),2)
    $_
}
```
<!--本文国际来源：[Checking Battery Wear and Quality](https://blog.idera.com/database-tools/powershell/powertips/checking-battery-wear-and-quality/)-->

