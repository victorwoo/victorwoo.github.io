---
layout: post
date: 2019-01-31 00:00:00
title: "PowerShell 技能连载 - 解析 Windows 安装日期"
description: PowerTip of the Day - Extracting Windows Installation Date
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
是否关心过您的 Windows 已经安装了多久？一个单行的代码可以告诉您结果：

```powershell
PS> (Get-CimInstance -Class Win32_OperatingSystem).InstallDate

Freitag, 8. Juni 2018 18:24:46
```

有两件事值得注意：第一，我们显然在使用德文的系统。第二，安装的日期可能比您想象的更近：每个新的 Windows 10 主版本更新实际上导致了一个完整的重新安装过程。

如果您希望改变 `DateTime` 输出的语言，只需要使用 `ToString()` 和一个 `CultureInfo` 对象：

```powershell
PS> (Get-CimInstance -Class Win32_OperatingSystem).InstallDate.ToString([System.Globalization.CultureInfo]'en-us')
6/8/2018 6:24:46 PM

PS>
```

如果您想了解 Windows 安装了多少填，请使用 `New-TimeSpan`：

```powershell
PS> New-TimeSpan -Start (Get-CimInstance -Class Win32_OperatingSystem).InstallDate


Days              : 204
Hours             : 18
Minutes           : 53
Seconds           : 52
Milliseconds      : 313
Ticks             : 176936323133869
TotalDays         : 204,787411034571
TotalHours        : 4914,89786482969
TotalMinutes      : 294893,871889782
TotalSeconds      : 17693632,3133869
TotalMilliseconds : 17693632313,3869


PS> (New-TimeSpan -Start (Get-CimInstance -Class Win32_OperatingSystem).InstallDate).TotalDays
204,78764150864

PS> (New-TimeSpan -Start (Get-CimInstance -Class Win32_OperatingSystem).InstallDate).Days
204
```

<!--本文国际来源：[Extracting Windows Installation Date](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/extracting-windows-installation-date)-->
