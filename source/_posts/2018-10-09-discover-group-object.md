---
layout: post
date: 2018-10-09 00:00:00
title: "PowerShell 技能连载 - 探索 Group-Object"
description: PowerTip of the Day - Discover Group-Object
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
`Group-Object` 是一个好用的 cmdlet：它可以方便地可视化分组。请查看以下示例：

```powershell
Get-Process | Group-Object -Property Company
Get-Eventlog -LogName System -EntryType Error | Group-Object -Property Source
Get-ChildItem -Path c:\windows -File | Group-Object -Property Extension
```

Basically, the cmdlet builds groups based on the content of a given property. You can also omit the group, and just look at the count if all that matters to you are the number distributions:
基本上，该 cmdlet 基于指定的属性内容创建分组。当您只关注数量分布时，也可以忽略该分组，而只查看总数。

```powershell
PS C:\> Get-ChildItem -Path c:\windows -File | Group-Object -Property Extension -NoElement | Sort-Object -Property Count -Descending



Count Name
----- ----
    10 .exe
    10 .log
    5 .ini
    4 .xml
    3 .dll
    2 .txt
    1 .dat
    1 .bin
    1 .tmp
    1 .prx
```

如果您对实际对象的分组更感兴趣，可以通过 `Group-Object` 来返回一个哈希表。通过这种方式，您可以通过他们的键访问每个特定的分组：

```powershell
$hash = Get-ChildItem -Path c:\windows -File |
    Group-Object -Property Extension -AsHashTable

$hash.'.exe'
```

执行的结果将转储 Windows 目录下所有扩展名为 ".exe" 的文件。请注意键（查询的属性）不为字符串的情况。

类似地，如果您使用 PowerShell 远程操作并且扇出到多台计算机来平行地获取信息，当获取到结果时，`Group-Object` 将会把结果重新分组。这个示例同时从三台机器获取服务信息，而且结果将以随机顺序返回。`Group-Object` 将会对输入的数据分组，这样您可以操作计算机的结果。和哈希表的操作方法一样，您可以用方括号或点号来存取哈希表的键：

```powershell
$services = Invoke-Command -ScriptBlock { Get-Service } -ComputerName server1, server2, server3 | Group-Object -Property PSComputerName -AsHashTable

$services["server1"]
$services."server2"
```

以下是一个类似的示例，但有一个 bug。您能指出错误吗？

```powershell
$hash = Get-Service |
    Group-Object -Property Status -AsHashTable

$hash.'Running'
```

当您查看哈希表时，您可能希望获取正在运行的服务：

```powershell
PS C:\> $hash

Name                           Value
----                           -----
Running                        {AdobeARMservice, AGMService, AGSService, App...
Stopped                        {AJRouter, ALG, AppIDSvc, AppMgmt...}
```

When you look at the hash table, you would expect to get back the running services:
然而，您并不会获得任何结果。那是因为哈希表中的那个键并不是字符串而是一个 "ServiceControllerStatus" 对象：

```powershell
PS C:\> $hash.Keys | Get-Member


    TypeName: System.ServiceProcess.ServiceControllerStatus
```

要确保获得到的是可存取的键，请总是将 `-AsHashTable` 和 `-AsString` 合并使用。后者确保把键转换为字符串。现在示例代码可以按预期工作：

```powershell
$hash = Get-Service |
    Group-Object -Property Status -AsHashTable -AsString

$hash.'Running'
```

<!--more-->
本文国际来源：[Discover Group-Object](http://community.idera.com/powershell/powertips/b/tips/posts/discover-group-object)
