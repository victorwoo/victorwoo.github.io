---
layout: post
date: 2022-11-08 00:00:00
title: "PowerShell 技能连载 - 获取系统正常运行时间"
description: PowerTip of the Day - Discover System Uptime
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`The Get-ComputerInfo` cmdlet 可以提供有关 Windows 客户端或服务器的大量信息，例如正常运行时间和其他相关信息。

试试以下代码：

```powershell
PS> Get-ComputerInfo | Select-Object -Property *Upt*

CsWakeUpType OsLastBootUpTime    OsUptime
------------ ----------------    --------
    PowerSwitch 25.10.2022 17:32:23 6.23:07:47.4872044
```

该命令获取所有名字中包含 "upt" 的属性，这些属性恰好都包含了和系统运行时间有关的信息。

当然，您还可以将信息存储到变量中，并单独查询属性：

```powershell
PS> $info = Get-ComputerInfo | Select-Object -Property *Upt*

PS> $info.OsUptime


Days              : 6
Hours             : 23
Minutes           : 9
Seconds           : 28
Milliseconds      : 617
Ticks             : 6017686177952
TotalDays         : 6,96491455781481
TotalHours        : 167,157949387556
TotalMinutes      : 10029,4769632533
TotalSeconds      : 601768,6177952
TotalMilliseconds : 601768617,7952


PS> $info.OsUptime.TotalHours
167,157949387556
```

由于属性值显示在一列中，它们显示为一行字符串。如果您单独查询它们，例如 `OsUptime`，它们将暴露它们的所有自身属性。

<!--本文国际来源：[Discover System Uptime](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/discover-system-uptime)-->

