---
layout: post
date: 2022-02-23 00:00:00
title: "PowerShell 技能连载 - 检测计划外的关机"
description: PowerTip of the Day - Detecting Unplanned Shutdown
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果 Windows 崩溃或意外停止，当下次重启时，它会产生一条 ID 为 41 的内核错误日志。如果您想检查回顾您的 Windows 是否正常关闭，请尝试以下代码：

```powershell
Get-EventLog -Logname System -Source "Microsoft-Windows-Kernel-Power" |
Where-Object EventID -eq 41 |
Select-Object Index,TimeWritten,Source,EventID
```

一种更现代且与 PowerShell 7 兼容的方式是使用 `Get-WinEvent`，而不是使用过滤器哈希表：

```powershell
Get-WinEvent -FilterHashtable @{
    LogName = 'System'
    ProviderName = 'Microsoft-Windows-Kernel-Power'
    Id = 41
}
```

<!--本文国际来源：[Detecting Unplanned Shutdown](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/detecting-unplanned-shutdown)-->

