---
layout: post
date: 2019-11-28 00:00:00
title: "PowerShell 技能连载 - Get-ComputerInfo 和 systeminfo.exe 的对比（第 2 部分）"
description: PowerTip of the Day - Get-ComputerInfo vs. systeminfo.exe (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerShell 5 中，引入了一个名为 `Get-ComputerInfo` 的新的 cmdlet，它完成曾经 systeminfo.exe 的功能，而 `Get-ComputerInfo` 是直接面向对象的。没有本地化的问题：

```powershell
$infos = Get-ComputerInfo
```

您现在可以查询您电脑独立的详情：

```powershell
$infos.OsInstallDate
$infos.OsFreePhysicalMemory
$infos.BiosBIOSVersion
```

或者使用 `Select-Object` 来选择所有兴趣的属性：

```powershell
$infos | Select-Object -Property OSInstallDate, OSFreePhysicalMemory, BiosBIOSVersion
```

在缺点方面，请考虑这一点：`Get-ComputerInfo` 是在 PowerShell 5 中引入的，您可以很容易地更新到该版本，或者将 PowerShell Core 与旧版本的 Windows PowerShell 并行使用。然而，`Get-ComputerInfo` 检索到的许多信息仅来自于最近的 Windows 操作系统中添加的 WMI 类。

如果您在 Windows 7 中更新到了 Windows PowerShell 5.1，`Get-ComputerInfo` 有可能不能正常工作。在旧的系统中，systeminfo.exe 是您的最佳依赖，而在新的操作系统中，`Get-ComputerInfo` 用起来方便得多。

<!--本文国际来源：[Get-ComputerInfo vs. systeminfo.exe (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/get-computerinfo-vs-systeminfo-exe-part-2)-->

