---
layout: post
date: 2021-07-12 00:00:00
title: "PowerShell 技能连载 - Forensic Event Log Analysis (Part 1)"
标题：《PowerShell 技能连载 - 取证事件日志分析（第 1 部分）》
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
Event logs log almost any aspect of Windows so if something goes wrong or stops working as expected, it is a good idea to include event log forensic strategies into your troubleshooting.
事件日志记录 Windows 的几乎所有方面，因此如果出现问题或停止按预期工作，最好将事件日志取证策略包含在故障排除中。

For example, some users reported that their Windows “Instant Search” stopped finding newer Email items. Why would the indexing service no longer update with Outlook?
例如，一些用户报告说他们的 Windows“即时搜索”停止查找更新的电子邮件项目。为什么索引服务不再随 Outlook 更新？

That’s when reading event logs can become very important (and helpful). The next line quickly finds out whether you have a systematic indexing problem. It searches the “Application” log for any errors related to “search”:
那时阅读事件日志会变得非常重要（并且很有帮助）。下一行快速找出您是否有系统索引问题。它在“应用程序”日志中搜索与“搜索”相关的任何错误：

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

Most apparently, in this example there seems to be a repeated systematic issue with the Mapi16 protocol handler that prevents the indexing service from reading Outlook Email.
最明显的是，在这个例子中，Mapi16 协议处理程序似乎存在重复的系统问题，阻止索引服务读取 Outlook 电子邮件。

To find out when the issue struck and whether it is still of concern, you can group event log entries and show their frequency:
要了解问题何时发生以及它是否仍然令人担忧，您可以将事件日志条目分组并显示它们的频率：

```powershell
PS> Get-EventLog -LogName Application -Source *search* -EntryType error |
    Group-Object { Get-Date $_.timegenerated -format yyyy-MM-dd } -NoElement
```

Group-Object in this example uses a script block to calculate the grouping criteria: Any error event occurring on the *same day* is placed into the same group which returns a chronologic protocol. Here is sample output:
本示例中的 Group-Object 使用脚本块来计算分组标准：在 *同一天* 发生的任何错误事件都被放入同一组中，该组返回一个时间顺序协议。这是示例输出：

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

The output clearly indicates that the issue started in April 30 and lasted until May 21 when it apparently was fixed.
输出清楚地表明该问题始于 4 月 30 日，一直持续到 5 月 21 日，当时它显然已得到修复。

Obviously, these examples won’t produce the same results on your machine (unless you experienced the same problem). They do show though how valuable event log information is and how easily PowerShell can help to forensically examine the data.
显然，这些示例不会在您的机器上产生相同的结果（除非您遇到相同的问题）。它们确实展示了事件日志信息的价值以及 PowerShell 可以多么轻松地帮助对数据进行取证检查。

<!--本文国际来源：[Forensic Event Log Analysis (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/forensic-event-log-analysis-part-1)-->

