---
layout: post
date: 2017-06-20 00:00:00
title: "PowerShell 技能连载 - 世界时钟"
description: PowerTip of the Day - World Time Clock
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 提供了 `Get-TimeZone` 命令，能返回所有定义过的时区和它们的时差。以下是列出世界时钟相关的代码：

```powershell
$isSummer = (Get-Date).IsDaylightSavingTime()


Get-TimeZone -ListAvailable | ForEach-Object { 
    $dateTime = [DateTime]::UtcNow + $_.BaseUtcOffset
    $cities = $_.DisplayName.Split(')')[-1].Trim()
    if ($isSummer -and $_.SupportsDaylightSavingTime)
    {
        $dateTime = $dateTime.AddHours(1)
    }
    '{0,-30}: {1:HH:mm"h"} ({2})' -f $_.Id, $dateTime, $cities
    }
```

结果类似如下：
     
    Dateline Standard Time         : 18:41h ()
    UTC-11                         : 19:41h (Coordinated Universal Time-11)
    Aleutian Standard Time         : 21:41h (Aleutian Islands)
    Hawaiian Standard Time         : 20:41h (Hawaii)
    Marquesas Standard Time        : 21:11h (Marquesas Islands)
    Alaskan Standard Time          : 22:41h (Alaska)
    UTC-09                         : 21:41h (Coordinated Universal Time-09)
    Pacific Standard Time (Mexico) : 23:41h (Baja California)
    UTC-08                         : 22:41h (Coordinated Universal Time-08)
    Pacific Standard Time          : 23:41h ()
    US Mountain Standard Time      : 23:41h (Arizona)
    Mountain Standard Time (Mexico): 00:41h (Chihuahua, La Paz, Mazatlan)
    Mountain Standard Time         : 00:41h ()
    Central America Standard Time  : 00:41h (Central America)
    Central Standard Time          : 01:41h ()
    Easter Island Standard Time    : 01:41h (Easter Island)
    Central Standard Time (Mexico) : 01:41h (Guadalajara, Mexico City, Monterrey)
    Canada Central Standard Time   : 00:41h (Saskatchewan)
    SA Pacific Standard Time       : 01:41h (Bogota, Lima, Quito, Rio Branco)
    Eastern Standard Time (Mexico) : 02:41h (Chetumal)
    Eastern Standard Time          : 02:41h ()

<!--本文国际来源：[World Time Clock](http://community.idera.com/powershell/powertips/b/tips/posts/world-time-clock)-->
