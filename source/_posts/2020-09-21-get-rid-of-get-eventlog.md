---
layout: post
date: 2020-09-21 00:00:00
title: "PowerShell 技能连载 - 摆脱 Get-EventLog"
description: PowerTip of the Day - Get Rid of Get-EventLog
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`Get-EventLog` 命令可以轻松访问主要的 Windows 事件日志中的事件日志条目，但是它既不能访问许多应用程序级事件日志，也不能在PowerShell 7中使用。

如果计划在 PowerShell 7 中运行代码，则应该开始习惯其后继程序：`Get-WinEvent`。此cmdlet功能强大，并支持许多参数。这是一个类似于 `Get-EventLog` 的示例：

```powershell
Get-WinEvent -FilterHashtable @{Logname = 'System';Level=2,3} -MaxEvents 10 |
    Select-Object TimeCreated, LevelDisplayName, Id, ProviderName, Message |
    Format-Table
```

您的查询以哈希表的形式提交，您可以看到如何指定日志名称和想要获取的事件数量。与 `Get-EventLog` 相比，您现在可以指定和检索任何日志，而不仅仅是少数经典日志。您可能需要运行 `Show-EventLog` 来打开事件日志查看器，并发现许多可用的应用程序级别的日志。

哈希表 “Level” 键定义您要查看的事件日志条目的类型。数字越低，条目越严重。“2” 代表错误，“3”代表警告。如您所见，您可以将级别组合为逗号分隔的列表。

结果看起来像这样：

    TimeCreated         LevelDisplayName    Id ProviderName                     Message
    -----------         ----------------    -- ------------                     -------
    04.08.2020 13:03:42 Warning          10016 Microsoft-Windows-DistributedCOM The Anwendungsspezifisch permission settings do...
    04.08.2020 13:03:20 Error                1 MTConfig                         An attempt to configure the input mode of a mul...
    04.08.2020 13:03:19 Error                1 MTConfig                         An attempt to configure the input mode of a mul...
    04.08.2020 12:58:18 Error                1 MTConfig                         An attempt to configure the input mode of a mul...
    04.08.2020 11:53:38 Error            10010 Microsoft-Windows-DistributedCOM The server Microsoft.SkypeApp_15.61.100.0_x86__...
    04.08.2020 11:23:48 Error            10010 Microsoft-Windows-DistributedCOM The server microsoft.windowscommunicationsapps_...
    04.08.2020 11:23:41 Error            10010 Microsoft-Windows-DistributedCOM The server Microsoft.SkypeApp_15.61.100.0_x86__...
    04.08.2020 11:23:37 Warning            701 Win32k                           Power Manager has not requested suppression of ...
    04.08.2020 11:23:37 Warning            701 Win32k                           Power Manager has not requested suppression of ...
    04.08.2020 11:23:37 Error            10317 Microsoft-Windows-NDIS           Miniport Microsoft Wi-Fi Direct Virtual Adapter...

<!--本文国际来源：[Get Rid of Get-EventLog](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/get-rid-of-get-eventlog)-->

