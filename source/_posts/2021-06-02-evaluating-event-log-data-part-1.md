---
layout: post
date: 2021-06-02 00:00:00
title: "PowerShell 技能连载 - 评估事件日志数据（第 1 部分）"
description: PowerTip of the Day - Evaluating Event Log Data (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
事件日志包含有关 Windows 系统几乎所有方面的非常有用的信息。但是，在使用已弃用的 `Get-EventLog` cmdlet 时，只能访问此信息的一小部分，因为此 cmdlet 只能访问较旧的经典日志。这就是该 cmdlet 从 PowerShell 7 中完全删除的原因。

在 PowerShell 3 中，添加了一个更快、更强大的替代 cmdlet：`et-WinEvent`。此 cmdlet 可以根据哈希表中提供的查询项过滤任何日志文件。

例如，此行代码转储所有事件日志文件中由 Windows Update Client 使用事件 ID 19 写入的所有事件：

```powershell
Get-WinEvent -FilterHashTable @{
    ID=19
    ProviderName='Microsoft-Windows-WindowsUpdateClient'
} | Select-Object -Property TimeCreated, Message
```

结果是已安装更新的列表：

    TimeCreated         Message
    -----------         -------
    05.05.2021 18:13:34 Installation erfolgreich: Das folgende Update wurde installiert. Security Intelligence-Update für
                        Microsoft Defender Antivirus - KB2267602 (Version 1.337.679.0)
    05.05.2021 00:11:33 Installation erfolgreich: Das folgende Update wurde installiert. Security Intelligence-Update für
                        Microsoft Defender Antivirus - KB2267602 (Version 1.337.615.0)
    04.05.2021 12:07:03 Installation erfolgreich: Das folgende Update wurde installiert. Security Intelligence-Update für
                        Microsoft Defender Antivirus - KB2267602 (Version 1.337.572.0)
    03.05.2021 23:54:58 Installation erfolgreich: Das folgende Update wurde installiert. Security Intelligence-Update für
                        Microsoft Defender Antivirus - KB2267602 (Version 1.337.528.0)
    ...

<!--本文国际来源：[Evaluating Event Log Data (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/evaluating-event-log-data-part-1)-->

