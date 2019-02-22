---
layout: post
date: 2017-10-02 00:00:00
title: "PowerShell 技能连载 - 准备磁盘驱动器"
description: PowerTip of the Day - Repairing Disk Drives
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
以前，我们用 `chkdsk.exe` 来修复磁盘。现在这个功能仍然能用。

从 Windows Server 2012 R2 和 Windows 8.1 开始，加入了一个新的 cmdlet，名字叫 `Repair-Volume`。类似 `chkdsk.exe` 它需要以管理员身份运行。

您可以用它来扫描驱动器的错误：

```powershell
PS> Repair-Volume -Scan -DriveLetter c
NoErrorsFound

PS>
```

您也可以使用 cmdlet 来修复错误：

`-OfflineScanAndFix` 选项：将卷置于脱机，扫描并且修复所有遇到的错误（相当于 `chkdsk /f`）。

`-SpotFix` 选项：暂时将卷置于脱机，并只修复记录在 `$corrupt` 文件中的错误（相当于 `chkdsk /spotfix`）。

<!--本文国际来源：[Repairing Disk Drives](http://community.idera.com/powershell/powertips/b/tips/posts/repairing-disk-drives)-->
