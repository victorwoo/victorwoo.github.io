---
layout: post
date: 2021-01-11 00:00:00
title: "PowerShell 技能连载 - 获取开机以来经历的时间"
description: PowerTip of the Day - Controlling Uptime
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 7 附带了一个名为 `Get-Uptime` 的新 cmdlet。它返回一个 timepan 对象，该对象具有自上次重新引导以来已过去的时间：

```powershell
PS> Get-Uptime


Days              : 9
Hours             : 23
Minutes           : 21
Seconds           : 14
Milliseconds      : 0
Ticks             : 8616740000000
TotalDays         : 9,9730787037037
TotalHours        : 239,353888888889
TotalMinutes      : 14361,2333333333
TotalSeconds      : 861674
TotalMilliseconds : 861674000
```

提交 `-Since` 参数时，它将返回上次重新启动的日期。

`Get-Uptime` 在 Windows PowerShell 中不可用，但是自行创建此命令很简单。运行以下代码在 Windows PowerShell 中创建自己的 `Get-Uptime` 命令：

```powershell
function Get-Uptime
{
    param([Switch]$Since)

    $date = (Get-CimInstance -Class Win32_OperatingSystem).LastBootUpTime
    if ($Since)
    {
        return $date
    }
    else
    {
        New-Timespan -Start $date
    }
}
```

<!--本文国际来源：[Controlling Uptime](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/controlling-uptime)-->

