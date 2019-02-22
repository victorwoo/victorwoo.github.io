---
layout: post
date: 2017-10-27 00:00:00
title: "PowerShell 技能连载 - 对比从 PowerShell 远程处理中受到的计算机数据"
description: PowerTip of the Day - Comparing Computer Data Received from PowerShell Remoting
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 远程处理是一个查询多台计算机的快速方法，因为 PowerShell 远程处理是并行工作的。以下是一个演示一系列有趣技术的真实案例。

目标是从两台计算机中获取正在运行的进程的列表，然后查找区别。

为了速度最快，进程列表是通过 PowerShell 远程处理和 `Invoke-Command`，并且结果是从两台计算机获得的。

要区分输入的数据，我们使用了 `Group-Object`。它通过计算机名对数据集分组。结果是一个哈希表，而计算机名是哈希表的键。

下一步，用 `Compare-Object` 来快速比较两个列表并查找区别：

```powershell
# get data in parallel via PowerShell remoting
# make sure you adjust the computer names
$computer1 = 'server1'
$computer2 = 'server2'
$data = Invoke-Command { Get-Process } -ComputerName $computer1, $computer2

# separate the data per computer
$infos = $data | Group-Object -Property PSComputerName -AsHashTable -AsString

# find differences in running processes
Compare-Object -ReferenceObject $infos.$computer1 -DifferenceObject $infos.$computer2 -Property ProcessName -PassThru |
  Sort-Object -Property ProcessName |
  Select-Object -Property ProcessName, Id, PSComputerName, SideIndicator
```

<!--本文国际来源：[Comparing Computer Data Received from PowerShell Remoting](http://community.idera.com/powershell/powertips/b/tips/posts/comparing-computer-data-received-from-powershell-remoting)-->
