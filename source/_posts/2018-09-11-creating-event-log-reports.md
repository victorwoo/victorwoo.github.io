---
layout: post
date: 2018-09-11 00:00:00
title: "PowerShell 技能连载 - 创建事件日志报告"
description: PowerTip of the Day - Creating Event Log Reports
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
您可能经常使用 `Get-EventLog` 来转储事件日志信息，例如：

```powershell
PS> Get-EventLog -LogName System -EntryType Error -Newest 6

    Index Time          EntryType   Source                 InstanceID Message
    ----- ----          ---------   ------                 ---------- -------
    5237 Jul 31 12:39  Error       DCOM                        10016 The des...
    5234 Jul 31 09:54  Error       DCOM                        10016 The des...
    5228 Jul 31 09:46  Error       DCOM                        10016 The des...
    5227 Jul 31 09:40  Error       DCOM                        10016 The des...
    5218 Jul 31 09:38  Error       DCOM                        10016 The des...
    5217 Jul 31 09:38  Error       DCOM                        10016 The des...



PS>
```

但是，如果您想创建有用的报告，请确保将输出表格格式化，并启用换行：

```powershell
PS> Get-EventLog -LogName System -EntryType Error -Newest 6 | Format-Table -AutoSize -Wrap
```

您现在可以方便地将结果输送到 `Out-File` 并创建有意义的文本报告。同时，设置其 `Width` 参数，以调整报告文件的宽度。

And if you don’t know the exact name of a particular log, simply use “*” for -LogName:
如果您不知道某个日志的确切名字，只需要将 `"*"` 赋给 `-LogName`：

```powershell
PS> Get-EventLog -LogName *

    Max(K) Retain OverflowAction        Entries Log
    ------ ------ --------------        ------- ---
    20.480      0 OverwriteAsNeeded      13.283 Application
        512      7 OverwriteOlder             98 Dell
    20.480      0 OverwriteAsNeeded           0 HardwareEvents
        512      7 OverwriteOlder              0 Internet Explorer
        512      7 OverwriteOlder             46 isaAgentLog
    20.480      0 OverwriteAsNeeded           0 Key Management Service
        128      0 OverwriteAsNeeded          97 OAlerts
                                                Security
    20.480      0 OverwriteAsNeeded       5.237 System
    15.360      0 OverwriteAsNeeded      10.279 Windows PowerShell
```

<!--more-->
本文国际来源：[Creating Event Log Reports](http://community.idera.com/powershell/powertips/b/tips/posts/creating-event-log-reports)
