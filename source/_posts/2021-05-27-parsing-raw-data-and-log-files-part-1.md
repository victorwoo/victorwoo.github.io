---
layout: post
date: 2021-05-27 00:00:00
title: "PowerShell 技能连载 - 解析原始数据和日志文件（第 1 部分）"
description: PowerTip of the Day - Parsing Raw Data and Log Files (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
大多数原始日志文件以表格形式出现：尽管它们可能不是功能齐全的 CSV 格式，但它们通常具有列和某种分隔符，有时甚至包含标题。

这是从 IIS 日志中获取的示例。当您查看它时时，会发现许多日志文件从根本上以表格方式组织它们的数据，如下所示：

    #Software: Microsoft Internet Information Services 10.0
    #Version: 1.0
    #Date: 2018-02-02 00:03:04
    #Fields: date time s-ip cs-method cs-uri-stem cs-uri-query s-port cs-username c-ip cs(User-Agent) cs(Referer) sc-status sc-substatus sc-win32-status time-taken
    2021-05-02 00:00:04 10.10.12.5 GET /Content/anonymousCheckFile.txt - 8530 - 10.22.121.248 - - 200 0 0 0
    2021-05-02 00:00:04 10.10.12.5 GET /Content/anonymousCheckFile.txt - 8531 - 10.22.121.248 - - 200 0 0 2

与编写复杂的代码来读取和解析日志文件的数据相比，将日志文件与标准 CSV 格式进行比较并查看是否可以这样处理会非常有价值。

在上面的 IIS 日志示例中，结果将是这样：

* 分隔符是一个空格（不是逗号）
* 字段（列名）记录在注释行（而不是标题行）中

知道这一点后，请使用 `Import-Csv`（用于 CSV 的快速内置 PowerShell 解析器）来快速解析日志文件并将其转换为对象。您需要做的就是告诉 `Import-Csv` 您的日志文件与标准 CSV 格式功能的不同之处：

```powershell
$Path = "c:\logs\l190202.log"

Import-Csv -Path $Path -Delimiter ' ' -Header date, time, s-ip, cs-method, cs-uri-stem, cs-uri-query, s-port, cs-username, c-ip, csUser-Agent, csReferer, sc-status ,sc-substatus, sc-win32-status, time-taken
```

在此示例中，使用 `-Delimiter` 告诉 `Import-Csv` 分隔符是一个空格，并且由于没有定义标题，请使用 `-Header` 并粘贴在开头的日志文件注释中找到的标题名称。

如果您不知道日志的标题名称，只需提供一个字符串数组，或使用此参数：

```
Import-Csv -Header (1..50)
```

这将为日志文件的列分配数字。

<!--本文国际来源：[Parsing Raw Data and Log Files (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/parsing-raw-data-and-log-files-part-1)-->
