layout: post
date: 2014-11-27 12:00:00
title: "PowerShell 技能连载 - 读取磁盘和分区信息"
description: PowerTip of the Day - Reading Disks and Partitions
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
_适用于 Windows 8.1 / Server 2012 R2_

Windows 8.1 和 Server 2012 R2 带来的许多客户端和服务器 cmdlet 可以极大地简化磁盘的管理。

让我们从查看磁盘和分区开始。这将列出所有加载的磁盘：

```
PS> Get-Disk
```

这将列出分区：

```
PS> Get-Partition
```

这两个 cmdlet 都位于“Storage”模块中：

```
PS> Get-Command -Name Get-Disk | Select-Object -ExpandProperty Module

ModuleType Version    Name                                ExportedCommands        
---------- -------    ----                                ----------------        
Manifest   2.0.0.0    Storage                             {Add-InitiatorIdToMas...
```

这将列出该模块中的所有存储管理命令：

```
PS> Get-Command -Module storage

CommandType     Name                                               ModuleName     
-----------     ----                                               ----------     
Alias           Flush-Volume                                       Storage        
Alias           Initialize-Volume                                  Storage        
Alias           Write-FileSystemCache                              Storage        
Function        Add-InitiatorIdToMaskingSet                        Storage        
Function        Add-PartitionAccessPath                            Storage        
Function        Add-PhysicalDisk                                   Storage      
(...)
```

<!--more-->
本文国际来源：[Reading Disks and Partitions](http://community.idera.com/powershell/powertips/b/tips/posts/reading-disks-and-partitions)
