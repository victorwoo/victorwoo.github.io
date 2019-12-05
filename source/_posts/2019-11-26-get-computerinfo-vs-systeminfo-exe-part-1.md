---
layout: post
date: 2019-11-26 00:00:00
title: "PowerShell 技能连载 - Get-ComputerInfo 和 systeminfo.exe 的对比（第 1 部分）"
description: PowerTip of the Day - Get-ComputerInfo vs. systeminfo.exe (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在很长一段时间内，命令行工具 `systeminfo.exe` 提供了大量计算机的信息，并且可以通过一个小技巧返回面向对象的结果：

```powershell
$objects = systeminfo.exe /FO CSV |
  ConvertFrom-Csv

$objects.'Available Physical Memory'
```

从好的一方面来说，systeminfo.exe 基本上在所有 Windows 系统中都可用。从坏的一方面来说，结果是语言本地化的，并且属性名可能会成为一个问题：在英文的系统中，一个属性可能名为 'Available Physical Memory' 而在一个德文系统中可能会不同。要使表头一致，您可以将它们去除并替换成自己的：

```powershell
$headers = 1..30 | ForEach-Object { "Property$_" }
$objects = systeminfo.exe /FO CSV |
  Select-Object -Skip 1 |
  ConvertFrom-Csv -Header $headers
```

以下是执行结果：

    PS> $objects


    Property1  : DESKTOP-8DVNI43
    Property2  : Microsoft Windows 10 Pro
    Property3  : 10.0.18362 N/A Build 18362
    Property4  : Microsoft Corporation
    Property5  : Standalone Workstation
    Property6  : Multiprocessor Free
    Property7  : hello@test.com
    Property8  : N/A
    Property9  : 00330-50000-00000-AAOEM
    Property10 : 9/3/2019, 11:42:41 AM
    Property11 : 11/1/2019, 10:42:53 AM
    Property12 : Dell Inc.
    Property13 : XPS 13 7390 2-in-1
    Property14 : x64-based PC
    Property15 : 1 Processor(s) Installed.,[01]: Intel64 Family 6 Model 126 Stepping 5
                 GenuineIntel ~1298 Mhz
    Property16 : Dell Inc. 1.0.9, 8/2/2019
    Property17 : C:\Windows
    Property18 : C:\Windows\system32
    Property19 : \Device\HarddiskVolume1
    Property20 : de;German (Germany)
    Property21 : de;German (Germany)
    Property22 : (UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna
    Property23 : 32,536 MB
    Property24 : 19,169 MB
    Property25 : 37,400 MB
    Property26 : 22,369 MB
    Property27 : 15,031 MB
    Property28 : C:\pagefile.sys
    Property29 : WORKGROUP
    Property30 : \\DESKTOP-8DVNI43




    PS> $objects.Property23
    32,536 MB

您可以通过在 `$headers` 中构造一个自定义的属性名列表，任意对属性命名：

```powershell
$headers = 'HostName',
            'OSName',
            'OSVersion',
            'OSManufacturer',
            'OSConfiguration',
            'OSBuildType',
            'RegisteredOwner',
            'RegisteredOrganization',
            'ProductID',
            'OriginalInstallDate',
            'SystemBootTime',
            'SystemManufacturer',
            'SystemModel',
            'SystemType',
            'Processors',
            'BIOSVersion',
            'WindowsDirectory',
            'SystemDirectory',
            'BootDevice',
            'SystemLocale',
            'InputLocale',
            'TimeZone',
            'TotalPhysicalMemory',
            'AvailablePhysicalMemory',
            'VirtualMemoryMaxSize',
            'VirtualMemoryAvailable',
            'VirtualMemoryInUse',
            'PageFileLocations',
            'Domain',
            'LogonServer',
            'Hotfix',
            'NetworkCard',
            'HyperVRequirements'

$objects = systeminfo.exe /FO CSV |
  Select-Object -Skip 1 |
  ConvertFrom-Csv -Header $headers

$objects.ProductID
```

<!--本文国际来源：[Get-ComputerInfo vs. systeminfo.exe (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/get-computerinfo-vs-systeminfo-exe-part-1)-->

