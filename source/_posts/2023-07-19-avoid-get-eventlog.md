---
layout: post
date: 2023-07-19 08:00:26
title: "PowerShell 技能连载 - 避免使用 Get-EventLog"
description: PowerTip of the Day - Avoid Get-EventLog
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`Get-EventLog` 是 Windows PowerShell 中非常受欢迎的 cmdlet。通过仅使用几个简单的参数，它可以从主要的 Windows 事件日志中读取事件日志。然而，这个 cmdlet 使用的技术不仅很慢，而且越来越危险。

`Get-EventLog` 在查找正确的事件消息时存在困难，所以过去经常得不到有意义的消息。然而，越来越频繁地，`Get-EventLog` 返回完全无关的错误消息，这可能会触发错误警报。就像这个例子：

```powershell
PS> Get-EventLog -Source Microsoft-Windows-Kernel-General -Newest 2 -LogName System -InstanceId 1

 Index Time         EntryType   Source                           InstanceID Message
 ----- ----         ---------   ------                           ---------- -------
551590 Jun 01 17:57 Information Microsoft-Windows-Kernel-General          1 Possible detection of CVE: 2023-06-01T15:57:15.025483...
551505 Mai 31 17:57 Information Microsoft-Windows-Kernel-General          1 Possible detection of CVE: 2023-05-31T15:57:13.842816...
```

CVE 检测是安全问题或入侵的指示器。你可不想成为那个在最后引发混乱的人，结果发现一切只是误报。任何其他工具都会返回相应的事件消息，正如官方替代 `Get-EventLog` 的工具：` Get-WinEvent` 也是如此：

```powershell
PS> Get-WinEvent -FilterHashtable @{
    ProviderName = 'Microsoft-Windows-Kernel-General'
    LogName = 'System'
    Id = 1
} -MaxEvents 2

ProviderName: Microsoft-Windows-Kernel-General
TimeCreated         Id LevelDisplayName Message
-----------         -- ---------------- -------
01.06.2023 17:57:15  1 Information      The system time has changed to ‎2023‎-‎06‎-‎01T15:57:15.025483100Z from ‎2023‎-‎06‎-‎01T1...
31.05.2023 17:57:13  1 Information      The system time has changed to ‎2023‎-‎05‎-‎31T15:57:13.842816200Z from ‎2023‎-‎05‎-‎31T1...
```

实际上，与 CVE 检测和安全问题不同，系统时间被调整了。

以后在脚本中不要再使用 Get-EventLog（除非你百分之百确定所关心的事件不受其缺点影响），而是要熟悉 `Get-WinEvent`：它更快、更多功能，并且还可以读取导出的事件文件。
<!--本文国际来源：[Avoid Get-EventLog](https://blog.idera.com/database-tools/powershell/powertips/avoid-get-eventlog/)-->

