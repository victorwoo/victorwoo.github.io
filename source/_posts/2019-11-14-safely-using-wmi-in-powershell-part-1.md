---
layout: post
date: 2019-11-14 00:00:00
title: "PowerShell 技能连载 - 在 PowerShell 中安全地使用 WMI（第 1 部分）"
description: PowerTip of the Day - Safely Using WMI in PowerShell (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
WMI (Windows Management Instrumentation) 是 Windows 操作系统的一部分并且广泛用于获取计算机系统的信息。PowerShell 之前引入了 `Get-WmiObject` 命令。在 PowerShell 3 中，增加了一个更现代的 `Get-CimInstance` 命令。

为了保持向后兼容，Windows PowerShell 始终保留了旧的 Get-WmiObject 命令，许多脚本开发者仍然在使用它而忽略了 `Get-CimInstance`。现在该是时候停止这个旧习惯因为 PowerShell Core (PowerShell 6, 7) 停止了对 `Get-WmiObject` 的支持。要确保脚本支持将来的 PowerShell 版本，您需要开始使用 Get-CimInstance 来代替 Get-WmiObject。

这刚开始看起来是微不足道的改变，实际上也确实是。对于简单的数据查询，您可能会通过 Get-CimInstance 来替换 Get-WmiObject：

```
PS> Get-WmiObject -Class Win32_BIOS

SMBIOSBIOSVersion : 1.0.9
Manufacturer      : Dell Inc.
Name              : 1.0.9
SerialNumber      : 4ZKM0Z2
Version           : DELL   - 20170001

PS> Get-CIMInstance -Class Win32_BIOS

SMBIOSBIOSVersion : 1.0.9
Manufacturer      : Dell Inc.
Name              : 1.0.9
SerialNumber      : 4ZKM0Z2
Version           : DELL   - 20170001
```

请注意在 `Get-CimInstance` 中 `-Class` 参数实际上改名为 `-ClassName`，但是由于 PowerShell 允许在参数名称唯一的情况下使用缩写，所以您无须改变参数名称。

然而，实际上 Get-WmiObject 和 Get-CimInstance 并不是 100% 兼容，并且您需要知道许多重要的区别，尤其是当您计划改变已有的脚本时。在这个迷你系列中，我们将看到最重要的实际差异。

让我们看看两个命令返回的信息。以下是一个查看返回属性的方法：

```powershell
# we are comparing this WMI class (feel free to adjust)
$wmiClass = 'Win32_OperatingSystem'

# get information about the WMI class Win32_OperatingSystem with both cmdlets
$a = Get-WmiObject -Class $wmiClass | Select-Object -First 1
$b = Get-CimInstance -ClassName $wmiClass | Select-Object -First 1

# dump the property names and add the property "Origin" so you know
# which property was returned by which command:
$aDetail = $a.PSObject.Properties | Select-Object -Property Name, @{N='Origin';E={'Get-WmiObject'}}
$bDetail = $b.PSObject.Properties | Select-Object -Property Name, @{N='Origin';E={'Get-CimInstance'}}

# compare the results:
Compare-Object -ReferenceObject $aDetail -DifferenceObject $bDetail -Property Name -PassThru |
  Sort-Object -Property Origin
```

以下是执行结果：

    Name                  Origin          SideIndicator
    ----                  ------          -------------
    CimClass              Get-CimInstance =>
    CimInstanceProperties Get-CimInstance =>
    CimSystemProperties   Get-CimInstance =>
    Qualifiers            Get-WmiObject   <=
    SystemProperties      Get-WmiObject   <=
    Properties            Get-WmiObject   <=
    ClassPath             Get-WmiObject   <=
    Options               Get-WmiObject   <=
    Scope                 Get-WmiObject   <=
    __PATH                Get-WmiObject   <=
    __NAMESPACE           Get-WmiObject   <=
    __SERVER              Get-WmiObject   <=
    __DERIVATION          Get-WmiObject   <=
    __PROPERTY_COUNT      Get-WmiObject   <=
    __RELPATH             Get-WmiObject   <=
    __DYNASTY             Get-WmiObject   <=
    __SUPERCLASS          Get-WmiObject   <=
    __CLASS               Get-WmiObject   <=
    __GENUS               Get-WmiObject   <=
    Site                  Get-WmiObject   <=
    Container             Get-WmiObject   <=

结果显示 metadata 中有显著的区别。`Get-WmiObject` 总是返回再起属性 "__Server"（两个下划线）中进行查询的计算机的名称而 `Get-WmiObject` 则是在 CimSystemProperties 中列出此信息：

```powershell
PS> $b.CimSystemProperties

Namespace  ServerName      ClassName     Path
---------  ----------      ---------     ----
root/cimv2 DESKTOP-8DVNI43 Win32_Process

PS> $b.CimSystemProperties.ServerName
DESKTOP-8DVNI43
```

不过，好消息是，类的特定属性并没有不同，因此这两个命令都返回有关操作系统、BIOS 或您所查询的其它内容的相同基本信息。这一行返回相同的属性：

```powershell
Compare-Object -ReferenceObject $aDetail -DifferenceObject $bDetail -Property Name -IncludeEqual -ExcludeDifferent -PassThru |  Sort-Object -Property Origin | Select-Object -Property Name, SideIndicator


Name                       SideIndicator
----                       -------------
ProcessName                ==
ParentProcessId            ==
PeakPageFileUsage          ==
PeakVirtualSize            ==
PeakWorkingSetSize         ==
Priority                   ==
PrivatePageCount           ==
ProcessId                  ==
QuotaNonPagedPoolUsage     ==
QuotaPagedPoolUsage        ==
QuotaPeakNonPagedPoolUsage ==
PageFileUsage              ==
QuotaPeakPagedPoolUsage    ==
PSComputerName             ==
ReadTransferCount          ==
SessionId                  ==
Status                     ==
TerminationDate            ==
ThreadCount                ==
UserModeTime               ==
VirtualSize                ==
WindowsVersion             ==
WorkingSetSize             ==
ReadOperationCount         ==
WriteOperationCount        ==
PageFaults                 ==
OtherOperationCount        ==
Handles                    ==
VM                         ==
WS                         ==
Path                       ==
Caption                    ==
CreationClassName          ==
CreationDate               ==
CSCreationClassName        ==
CSName                     ==
Description                ==
OtherTransferCount         ==
CommandLine                ==
ExecutionState             ==
Handle                     ==
HandleCount                ==
InstallDate                ==
KernelModeTime             ==
MaximumWorkingSetSize      ==
MinimumWorkingSetSize      ==
Name                       ==
OSCreationClassName        ==
OSName                     ==
```

<!--本文国际来源：[Safely Using WMI in PowerShell (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/safely-using-wmi-in-powershell-part-1)-->

