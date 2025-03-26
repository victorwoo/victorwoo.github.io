---
layout: post
date: 2022-07-11 00:00:00
title: "PowerShell 技能连载 - 恢复被浪费的硬盘空间"
description: PowerTip of the Day - Recovering Wasted Hard Drive Space
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当软件收到更新时，它往往并不会清除之前不需要的更新。这些过期的“补丁文件”积累在 C:\Windows\installer 文件夹下，其中有许多 *.msp 文件。由于您不知道那些 *.msp 文件还会被用到，以及哪个文件可以安全地删除，所以不太容易恢复空间。除非您拥有 Administrator 特权（需要它才能处理存储在 Windows 文件夹中的数据）并使用 PowerShell。

只需要下载该模块（需要 Administrator 特权）：

```powershell
Install-Module -Name MSIPatches
```

下一步，以 Administrator 特权启动一个 PowerShell 控制台，并像这样查看可恢复的空间：

```powershell
PS> Get-MsiPatch


TotalPatchCount     : 19
TotalPatchSize      : 0,96 GB
InstalledPatchCount : 5
InstalledPatchSize  : 0,32 GB
OrphanedPatchCount  : 14
OrphanedPatchSize   : 3,64 GB
```

"Orphaned Patch Size" 可能是 0 到好几 GB 之间的任意值。在一个系统上，由于安装了 Office 2016，我恢复了 45GB 的孤儿补丁（显然没有清理已安装的更新）。


要真正清理不必要的补丁，请使用此行代码（需要管理员特权）：

```powershell
Get-OrphanedPatch | Move-OrphanedPatch -Destination C:\Backup
```

这样，您可以在安全的地方“隔离”补丁文件一段时间。不过，不要忘记在某个时间点清空目标文件夹。或者，您当然可以立即删除孤立的补丁。不过，无论您做什么，都要自担风险。

<!--本文国际来源：[Recovering Wasted Hard Drive Space](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/recovering-wasted-hard-drive-space)-->

