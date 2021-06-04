---
layout: post
date: 2021-05-31 00:00:00
title: "PowerShell 技能连载 - 解析原始数据和日志文件（第 2 部分）"
description: PowerTip of the Day - Parsing Raw Data and Log Files (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技能中，我们解释了大多数日志文件可以被视为 CSV 文件并由 `Import-Csv` 读取。您需要做的就是告诉 `Import-Csv` 您的日志文件与标准 CSV 的不同之处，例如定义不同的分隔符或提供缺少的标题。

然而，一种日志文件格式很难解析：固定宽度的列。在这种情况下，没有可使用的单个分隔符。相反，数据使用固定宽度的字符串。

为了说明这种类型的数据，在 Windows 上运行实用程序 `qprocess.exe`。它返回固定宽度的数据（列出正在运行的进程、它们的所有者和它们的连接会话）。下面的示例取自德语操作系统，但本地化的列标题在这里并不重要。更重要的是每列使用固定的字符串宽度而不是单个分隔符，因此 `ConvertFrom-Csv` 无法读取数据：

```powershell
PS> qprocess
    BENUTZERNAME          SITZUNGSNAME        ID    PID  ABBILD
>tobia                 console              1   9332  dptf_helper.exe
>tobia                 console              1   9352  mbamtray.exe
>tobia                 console              1   9440  sihost.exe
>tobia                 console              1   9472  svchost.exe
...

PS> qprocess | ConvertTo-Csv
#TYPE System.String
"Length"
"60"
...
```

不过，对于固定宽度数据，您可以使用简单的正则表达式将可变空白替换为固定宽度分隔符：

```powershell
PS> (qprocess) -replace '\s{1,}',','
,BENUTZERNAME,SITZUNGSNAME,ID,PID,ABBILD
>tobia,console,1,9332,dptf_helper.exe
>tobia,console,1,9352,mbamtray.exe
>tobia,console,1,9440,sihost.exe
...
```

现在您获得了有效的 CSV。由于 `qprocess` 返回一个字符串数组，您可以稍微微调数据，例如从每一行中删除不需要的字符：

```powershell
PS> (qprocess).TrimStart(' >') -replace '\s{1,}',','
BENUTZERNAME,SITZUNGSNAME,ID,PID,ABBILD
tobia,console,1,9332,dptf_helper.exe
tobia,console,1,9352,mbamtray.exe
tobia,console,1,9440,sihost.exe
...
```

<!--本文国际来源：[Parsing Raw Data and Log Files (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/parsing-raw-data-and-log-files-part-2)-->
