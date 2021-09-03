---
layout: post
date: 2021-07-12 00:00:00
title: "PowerShell 技能连载 - 取证事件日志分析（第 1 部分）"
description: PowerTip of the Day - Forensic Event Log Analysis (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
事件日志记录 Windows 几乎所有方面的信息，因此如果出现问题或停止按预期工作，最好将事件日志取证策略包含在故障排除中。

例如，一些用户报告说他们的 Windows“即时搜索”停止查找更新的电子邮件项目。为什么索引服务不再随 Outlook 更新？

那时阅读事件日志会变得非常重要（并且很有帮助）。下面这行代码能快速找出您是否有系统索引问题。它在“应用程序”日志中搜索与“搜索”相关的任何错误：

```powershell
PS> Get-EventLog -LogName Application -Source *search* -EntryType error -Newest 10 |
        Select-Object TimeGenerated, Message

TimeGenerated       Message
-------------       -------
21.05.2021 09:55:48 The protocol handler Mapi16 cannot be loaded. Error description: (HRES...
21.05.2021 09:48:03 The protocol handler Mapi16 cannot be loaded. Error description: (HRES...
21.05.2021 08:55:14 The protocol handler Mapi16 cannot be loaded. Error description: (HRES...
21.05.2021 08:47:53 The protocol handler Mapi16 cannot be loaded. Error description: (HRES...
21.05.2021 08:32:15 The protocol handler Mapi16 cannot be loaded. Error description: (HRES...
21.05.2021 08:28:41 The protocol handler Mapi16 cannot be loaded. Error description: (HRES...
21.05.2021 08:26:18 The protocol handler Mapi16 cannot be loaded. Error description: (HRES...
20.05.2021 18:14:48 The protocol handler Mapi16 cannot be loaded. Error description: (HRES...
20.05.2021 12:55:06 The protocol handler Mapi16 cannot be loaded. Error description: (HRES...
20.05.2021 11:41:06 The protocol handler Mapi16 cannot be loaded. Error description: (HRES...
```

最明显的是，在这个例子中，Mapi16 协议处理程序似乎存在重复的系统问题，阻止索引服务读取 Outlook 电子邮件。

要了解问题何时发生以及它是否仍然令人担忧，您可以将事件日志条目分组并显示它们的频率：

```powershell
PS> Get-EventLog -LogName Application -Source *search* -EntryType error |
    Group-Object { Get-Date $_.timegenerated -format yyyy-MM-dd } -NoElement
```

本示例中的 `Group-Object` 使用脚本块来计算分组标准：在 *同一天* 发生的任何错误事件都被放入同一组中，该组返回一个时间顺序协议。这是示例输出：

    Count Name
    ----- ----
        7 2021-05-21
        6 2021-05-20
       29 2021-05-19
       29 2021-05-18
       16 2021-05-17
        5 2021-05-16
        2 2021-05-15
        8 2021-05-14
        2 2021-05-13
        3 2021-05-12
        9 2021-05-11
       13 2021-05-10
        1 2021-05-09
        3 2021-05-08
        7 2021-05-07
       10 2021-05-06
       15 2021-05-05
        8 2021-05-04
       24 2021-05-03
       22 2021-05-02
       10 2021-05-01
        2 2021-04-30

输出清楚地表明该问题始于 4 月 30 日，一直持续到 5 月 21 日，当时它显然已得到修复。

显然，这些示例不会在您的机器上产生相同的结果（除非您遇到相同的问题）。它们确实展示了事件日志信息的价值以及 PowerShell 可以多么轻松地帮助对数据进行取证检查。

<!--本文国际来源：[Forensic Event Log Analysis (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/forensic-event-log-analysis-part-1)-->

