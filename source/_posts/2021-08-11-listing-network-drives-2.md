---
layout: post
date: 2021-08-11 00:00:00
title: "PowerShell 技能连载 - 列出网络驱动器"
description: PowerTip of the Day - Listing Network Drives
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
There are many ways to list mapped network drives. One of them uses PowerShell’s Get-PSDrive and checks to see whether the target root starts with “\\”, indicating a UNC network path:
有很多方法可以列出映射的网络驱动器。其中之一使用 PowerShell 的 `Get-PSDrive` 并检查目标根目录是否以 "\\" 开头，表示 UNC 网络路径：

```powershell
PS> Get-PSDrive -PSProvider FileSystem | Where-Object DisplayRoot -like '\\*'

Name           Used (GB)     Free (GB) Provider      Root                    CurrentLocation
----           ---------     --------- --------      ----                    ---------------
Z               11076,55          0,00 FileSystem    \\192.168.2.107\docs
```

一个不错的方面是 `Get-PSDrive` 返回有用的附加详细信息，例如驱动器的大小。

<!--本文国际来源：[Listing Network Drives](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/listing-network-drives-2)-->

