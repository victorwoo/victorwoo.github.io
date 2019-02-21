---
layout: post
date: 2019-02-19 00:00:00
title: "PowerShell 技能连载 - 等待服务状态变化"
description: PowerTip of the Day - Waiting for a Service Status Change
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
当您启动或停止一个服务时，可能需要一些时间才能确保服务进入指定的状态——或者它当然可能会失败。当您使用 `Stop-Service` 时，PowerShell 将等待该服务状态已确认。如果您希望获得其它地方初始化的服务响应，以下是一段监听代码，它将会暂停 PowerShell 直到服务变为指定的状态：

```powershell
# wait 5 seconds for spooler service to stop
$serviceToMonitor = Get-Service -Name Spooler
$desiredStatus = [System.ServiceProcess.ServiceControllerStatus]::Stopped
$maxTimeout = New-TimeSpan -Seconds 5

try
{
  $serviceToMonitor.WaitForStatus($desiredStatus, $maxTimeout)
}
catch [System.ServiceProcess.TimeoutException]
{
  Write-Warning 'Service did not reach desired status within timeframe.'
}
```

您可以使用这段代码来响应由外部系统触发的服务改变，或者当您要求服务状态更改后做二次确认。

今日的知识点：

* 您从 cmdlet 获得的多数对象（例如 `Get-Service`）有许多有用的方法。所有服务对象都有一个 `WaitForStatus` 方法。在我们的例子中演示了如何使用它。
* 要发现隐藏在对象中的其它方法，请使用以下代码：

```powershell
# get some object 
$objects = Get-Process 

# dump the methods
$objects | Get-Member -MemberType *method* | Select-Object -Property Name, Definition
```

<!--more-->
本文国际来源：[Waiting for a Service Status Change](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/waiting-for-a-service-status-change)
