---
layout: post
date: 2020-07-01 00:00:00
title: "PowerShell 技能连载 - 操作系统的启动和安装时间"
description: PowerTip of the Day - Boot and Install Time for Operating System
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
WMI 类 `Win32_OperatingSystem` 提供了有关许多日期时间信息的丰富信息，包括上次启动的日期和安装时间：

```powershell
$dateTimeProps = 'InstallDate', 'LastBootupTime', 'LocalDateTime', 'CurrentTimeZone', 'CountryCode'

Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -Property $dateTimeProps
```

结果看起来像这样：

    InstallDate     : 03.09.2019 12:42:41
    LastBootupTime  : 03.05.2020 12:15:45
    LocalDateTime   : 04.05.2020 10:43:55
    CurrentTimeZone : 120
    CountryCode     : 49

如果您想知道系统运行了多少分钟，或者自安装以来已经过去了几天，请使用 New-TimeSpan：

```powershell
$os = Get-CimInstance -ClassName Win32_OperatingSystem

$installedDays = (New-TimeSpan -Start $os.InstallDate).Days
$runningMinutes = [int](New-TimeSpan -Start $os.LastBootupTime).TotalMinutes

"Your copy of Windows was installed $installedDays days ago."
"Your system is up for {0:n0} minutes." -f $runningMinutes
```

结果看起来像这样：

    Your copy of Windows was installed 243 days ago.
    Your system is up for 1.353 minutes.

`Get-CimInstance` cmdlet可用于在本地和远程计算机上查询信息（前提是您具有适当的权限）。有关如何远程使用Get-CimInstance的更多信息，请访问<https://powershell.one/wmi/remote-access>。

<!--本文国际来源：[Boot and Install Time for Operating System](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/boot-and-install-time-for-operating-system)-->

