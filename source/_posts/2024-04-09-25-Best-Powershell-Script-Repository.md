---
layout: post
date: 2024-04-09 00:00:00
title: "PowerShell 技能连载 - 25个最佳的Powershell脚本仓库"
description: "25+ Best Powershell Script Repository"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
我最喜欢的部分之一是创建略有不同的脚本，我在这方面也取得了成功，并创建了Powershell脚本存储库。今天我必须说，我已经记不清自己创建了多少个脚本。除了[AD](https://powershellguru.com/active-directory-powershell-scripts/)、[DNS](https://powershellguru.com/dns-powershell-scripts/)和[DHCP](https://powershellguru.com/dhcp-powershell-scripts/)之外，此存储库还包含许多其他必备的脚本。从GPO到DFS Powershell脚本以及许多其他相关的Powershell脚本，使我的工作团队体验达到第九云。

这些脚本显然是为自动化而创建的，并且将它们保留在手头上被认为是犯罪行为，因此展示在该类别中。虽然我们知道组策略在任何环境中设置规则时起着重要作用，并且DFS也很重要，那么为什么不通过查看下面推荐书籍来更深入地了解它们呢？

## 为您提供的有用PowerShell命令

获取所有组策略命令

```powershell
Get-command -Module grouppolicy
```

获取 GPO 报告

```powershell
Get-GPOReport -All -Domain xyz.com
```

重置 GPO

```powershell
Restore-GPO -Name "GPOname" -Path \\Server1\Backups
```

备份 GPO

```powershell
Backup-Gpo -All -Path \\Server1\GpoBackups
```

获取DFS复制组

```powershell
Get-DfsReplicationGroup -GroupName RG02
```

获取DFS复制成员

```powershell
Get-DfsrMember -GroupName "RG07" -ComputerName "SRV01"
```

重启多台计算机

```powershell
Restart-computer -computername A,B,C
```

获取所有服务

```powershell
Get-service
```

## 我的Powershell脚本仓库

* [Map drive](https://powershellguru.com/wp-content/uploads/2021/03/map-drive.zip)
* [Create server Inventory](https://powershellguru.com/wp-content/uploads/2021/03/Inventory.txt)
* [Server uptime report](https://e37eec5f-8071-43d6-a9d1-0b9ae629dd33.usrfiles.com/ugd/e37eec_07a42e4c688442f4b3079f9d8df841cf.txt)
* [Memory and CPU utilization from multiple servers](https://e37eec5f-8071-43d6-a9d1-0b9ae629dd33.usrfiles.com/ugd/e37eec_807f866e457d40c98135585b20e61031.txt)
* [Patch Management](https://e37eec5f-8071-43d6-a9d1-0b9ae629dd33.usrfiles.com/ugd/e37eec_c9d2a9d02af3454c98b3f6f9dab28077.txt)
* [Disk Space Report](https://e37eec5f-8071-43d6-a9d1-0b9ae629dd33.usrfiles.com/ugd/e37eec_83412bfc24c643b1a8434eb07a0aa553.txt)
* [Get process and user running it](https://powershellguru.com/wp-content/uploads/2021/03/get-process-and-user-running-it.txt)
* [Software installation on multiple server](https://powershellguru.com/wp-content/uploads/2021/03/Software-installation-on-multiple-server.txt)
* [Search file type](https://powershellguru.com/wp-content/uploads/2021/03/Search-file-type-1.txt)
* [Deleting print queues](https://powershellguru.com/wp-content/uploads/2021/03/Deleting-print-queues.txt)
* [Script to check who rebooted](https://powershellguru.com/wp-content/uploads/2021/03/Sript-for-who-reboot-2.txt)
* [Restart multiple Computers](https://powershellguru.com/wp-content/uploads/2021/03/Restart-multiple-Computers-1.txt)
* [NIC details](https://powershellguru.com/wp-content/uploads/2021/03/NIC-card-details.txt)
* [Check Local admin](https://powershellguru.com/wp-content/uploads/2021/03/Local-admin-1.txt)
* [DFS Replication status](https://powershellguru.com/wp-content/uploads/2021/03/DFSR.txt)
* [Ping status](https://powershellguru.com/wp-content/uploads/2021/03/ping-1.txt)
* [GPO creation and Deletion](https://powershellguru.com/wp-content/uploads/2021/03/Wintel-AD-GPO-creation-and-Deletion.txt)
* [Check for SMB v1 and SMB v2](https://powershellguru.com/wp-content/uploads/2021/03/Find-Smbv1v2-1.txt)
* [Service Status](https://powershellguru.com/wp-content/uploads/2021/03/service.txt)
* [OS License Checker](https://powershellguru.com/wp-content/uploads/2021/03/OS-License.txt)
* [Restore GPO](https://powershellguru.com/wp-content/uploads/2021/03/Restore_GPO.txt)
* [OS-Page File Configuration](https://powershellguru.com/wp-content/uploads/2021/03/Wintel-OS-Page-File-Configuration-1.txt)
* [Pre-Patch checker](https://e37eec5f-8071-43d6-a9d1-0b9ae629dd33.usrfiles.com/ugd/e37eec_65f3ca124a644a57b84ea2b64bb53a12.txt)
* [Certificate Expiry checker](https://powershellguru.com/wp-content/uploads/2021/03/certificate-1.txt)
* [Share drive size](https://powershellguru.com/wp-content/uploads/2021/03/shares-1.txt)
