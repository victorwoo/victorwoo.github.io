---
layout: post
date: 2021-10-14 00:00:00
title: "PowerShell 技能连载 - 将 UNIX 时间转为 DateTime"
description: PowerTip of the Day - Converting UNIX Time to DateTime
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
“UNIX时间”计算自 01/01/1970 以来经过的秒数。

例如，在 Windows 中，您可以从 Windows 注册表中读取安装日期，返回的值为 “Unix时间”：

```powershell
$values = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
$installDateUnix = $values.InstallDate

$installDateUnix
```

结果是类似这样的大数字：

    1601308412


To convert “Unix time” to a real DateTime value, .NET Framework provides a type called [DateTimeOffset]:
要将“UNIX时间”转换为真实的 `DateTime` 值，请使用 .NET Framework 提供的 `[DateTimeOffset]` 类：

```powershell
$values = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
$installDateUnix = $values.InstallDate

[DateTimeOffset]::FromUnixTimeSeconds($installDateUnix)
```

现在您能得到不同的日期和时间表示：

    DateTime      : 28.09.2020 15:53:32
    UtcDateTime   : 28.09.2020 15:53:32
    LocalDateTime : 28.09.2020 17:53:32
    Date          : 28.09.2020 00:00:00
    Day           : 28
    DayOfWeek     : Monday
    DayOfYear     : 272
    Hour          : 15
    Millisecond   : 0
    Minute        : 53
    Month         : 9
    Offset        : 00:00:00
    Second        : 32
    Ticks         : 637369052120000000
    UtcTicks      : 637369052120000000
    TimeOfDay     : 15:53:32
    Year          : 2020

要获取本地格式的安装时间，您可以在一行代码中写完它：

```powershell
PS> [DateTimeOffset]::FromUnixTimeSeconds((Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').InstallDate).DateTime

Moday, September 28, 2020 15:53:32
```

<!--本文国际来源：[Converting UNIX Time to DateTime](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/converting-unix-time-to-datetime)-->

