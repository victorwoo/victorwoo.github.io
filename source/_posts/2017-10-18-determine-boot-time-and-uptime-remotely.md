---
layout: post
date: 2017-10-18 00:00:00
title: "PowerShell 技能连载 - 远程确定启动时间点和启动以来的时间"
description: PowerTip of the Day - Determine Boot Time and Uptime Remotely
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`Get-CimInstance` 是一个用来获取 WMI 信息的有用的 cmdlet，因为它使用标准的 .NET DateTime 对象，而不是奇怪的 WMI datetime 格式。然而，`Get-CimInstance` 使用 WinRM 来进行远程访问，而传统的 `Get-WmiObject` 使用 DCOM 来进行远程访问。

非常古老的系统可能还没有配置为使用 WinRM 远程处理，并且可能仍然需要 DCOM。以下是演示如何使用 `Get-CimInstance` 和 DOM 来查询非常古老的机器的示例代码：

```powershell
# change computer name to a valid remote system that you
# can access remotely
$computername = 'server12'

# use DCOM for older systems that do not run with WinRM remoting
$option = New-CimSessionOption -Protocol Dcom
$session = New-CimSession -ComputerName $computername -SessionOption $option

$bootTime = Get-CimInstance -ClassName Win32_OperatingSystem -CimSession $session | Select-Object -ExpandProperty LastBootupTime
$upTime = New-TimeSpan -Start $bootTime

$min = [int]$upTime.TotalMinutes
"Your system is up for $min minutes now."

Remove-CimSession -CimSession $session
```

<!--本文国际来源：[Determine Boot Time and Uptime Remotely](http://community.idera.com/powershell/powertips/b/tips/posts/determine-boot-time-and-uptime-remotely)-->
