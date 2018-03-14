---
layout: post
date: 2018-03-07 00:00:00
title: "PowerShell 技能连载 - 查找注册过的事件日志数据源名"
description: PowerTip of the Day - Finding Registered Event Log Source Names
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
当您用 Write-EventLog 将日志写入日志记录时，您需要指定一个合法的事件源名称。然而，并没有一个很方便的办法能查出哪个事件源文件对应注册到某个事件日志。这在您用 `New-EventLog` 创建新的事件日志时可能会带来麻烦：您不能指定一个已经存在的事件源名称。

以下是一个查找所有事件源名称，并且显示它们注册的事件日志的简单方法：

```powershell
PS> Get-WmiObject -Class Win32_NTEventLOgFile | Select-Object FileName, Sources


FileName               Sources
--------               -------
Application            {Application, .NET Runtime, .NET Runtime Optimization Service, Application Error...}
Dell                   {Dell, DigitalDelivery, Update}
HardwareEvents         {HardwareEvents}
Internet Explorer      {Internet Explorer}
isaAgentLog            {isaAgentLog, isaAgent}
Key Management Service {Key Management Service, KmsRequests}
OAlerts                {OAlerts, Microsoft Office 16 Alerts}
PowerShellPrivateLog   {PowerShellPrivateLog, Debug, Logon, Misc...}
PreEmptive             {PreEmptive, PreEmptiveAnalytics}
Security               {Security, DS, LSA, Microsoft-Windows-Eventlog...}
System                 {System, 3ware, ACPI, ADP80XX...}
TechSmith              {TechSmith, TechSmith Uploader Service}
Windows PowerShell     {Windows PowerShell, PowerShell}
```

您还可以将这个列表转换为一个有用的哈希表：

```powershell
# find all registered sources
$Sources = Get-WmiObject -Class Win32_NTEventLOgFile |
    Select-Object FileName, Sources |
    ForEach-Object -Begin { $hash = @{}} -Process { $hash[$_.FileName] = $_.Sources } -end { $Hash }

# list sources for application log
$Sources["Application"]

# list sources for system log
$Sources["System"]
```

<!--more-->
本文国际来源：[Finding Registered Event Log Source Names](http://community.idera.com/powershell/powertips/b/tips/posts/finding-registered-event-log-source-names)
