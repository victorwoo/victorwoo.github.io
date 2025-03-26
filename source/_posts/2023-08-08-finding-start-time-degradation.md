---
layout: post
date: 2023-08-08 08:00:29
title: "PowerShell 技能连载 - 寻找开始时间退化"
description: PowerTip of the Day - Finding Start Time Degradation
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
具有管理员权限的Windows系统可以访问在启动过程中收集到的诊断数据。Windows会记录每个服务和子系统的启动时间和降级时间（以毫秒为单位）。通过这些数据，您可以识别出需要花费过多时间来启动的服务可能存在的问题。

以下是一个脚本，它读取相应的日志文件条目并返回测量得到的启动时间：

```powershell
#requires -RunAsAdmin

$Days = 180

$machineName = @{
    Name = 'MachineName'
    Expression = { $env:COMPUTERNAME }
}

$FileName = @{
        Name = 'FileName';
        Expression = { $_.properties[2].value }
}

$Name = @{
        Name = 'Name';
        Expression = { $_.properties[4].value }
}

$Version = @{
        Name = 'Version'
        Expression = { $_.properties[6].value }
}

$TotalTime = @{
        Name = 'TotalTime'
        Expression = { $_.properties[7].value }
}

$DegradationTime = @{
        Name = 'DegradationTime'
        Expression = { $_.properties[8].value }
}

Get-WinEvent -FilterHashtable @{
    LogName='Microsoft-Windows-Diagnostics-Performance/Operational'
    Id=101
    StartTime = (Get-Date).AddDays(-$Days)
    Level = 1,2
} |
  Select-Object -Property $MachineName, TimeCreated,
                          $FileName, $Name, $Version,
                          $TotalTime, $DegradationTime, Message |
  Out-GridView
```
<!--本文国际来源：[Finding Start Time Degradation](https://blog.idera.com/database-tools/powershell/powertips/finding-start-time-degradation/)-->

