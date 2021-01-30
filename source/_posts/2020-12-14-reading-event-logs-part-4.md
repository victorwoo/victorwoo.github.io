---
layout: post
date: 2020-12-14 00:00:00
title: "PowerShell 技能连载 - 读取事件日志（第 4 部分）"
description: PowerTip of the Day - Reading Event Logs (Part 4)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技巧中，我们鼓励您弃用 `Get-EventLog` cmdlet，而开始使用 `Get-WinEvent`，因为后者功能更强大，并且在PowerShell 7 中不再支持前者。

如上例所示，通过 `Get-WinEvent` 查询事件需要一个哈希表。例如，以下命令返回已安装更新的列表：

```powershell
Get-WinEvent -FilterHashtable @{
  LogName = 'System'
  ProviderName = 'Microsoft-Windows-WindowsUpdateClient'
  Id = 19
  }
```

实际上，事件数据始终使用 XML 格式存储，并且所有查询都使用 XPath 过滤器查询来为您检索数据。如果您是 XML 和XPath专家，则可以直接使用以下命令来获得相同的结果：

```powershell
Get-WinEvent -FilterXML @'
<QueryList><Query Id="0" Path="system"><Select Path="system">*[System/Provider[@Name='microsoft-windows-windowsupdateclient'] and (System/EventID=19)]</Select></Query></QueryList>
'@
```

哈希表是一个很方便的快捷方式。在内部，哈希表中包含的信息将转换为上面的 XML 语句。幸运的是，将哈希表转换为 XML 一点也不困难，因为 Get-WinEvent 会为您做到这一点：只需提交一个哈希表，并要求返回 XML 语句：

```powershell
$result = Get-WinEvent -FilterHashtable @{
  LogName = 'System'
  ProviderName = 'Microsoft-Windows-WindowsUpdateClient'
  Id = 19
  } -MaxEvents 1 -Verbose  4>&1

$result | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] }
```

本质上，通过提交 `-Verbose` 参数，要求 `Get-WinEvent` 将计算出的XML语句返回给您。通过将管道 4 重定向到输出管道 1，您可以将详细消息捕获到 `$result` 并过滤详细消息。这样，您可以捕获计算出的XML：

    VERBOSE: Found matching provider: Microsoft-Windows-WindowsUpdateClient
    VERBOSE: The Microsoft-Windows-WindowsUpdateClient provider writes events to the System log.
    VERBOSE: The Microsoft-Windows-WindowsUpdateClient provider writes events to the Microsoft-Windows-WindowsUpdateClient/Operational log.
    VERBOSE: Constructed structured query:
    VERBOSE: <QueryList><Query Id="0" Path="system"><Select Path="system">*[System/Provider[@Name='microsoft-windows-windowsupdateclient'] and
    VERBOSE: (System/EventID=19)]</Select></Query></QueryList>.

<!--本文国际来源：[Reading Event Logs (Part 4)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/reading-event-logs-part-4)-->

