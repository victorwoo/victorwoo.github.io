---
layout: post
date: 2014-08-26 11:00:00
title: "PowerShell 技能连载 - 获取 WMI 设备清单"
description: 'PowerTip of the Day - WMI Device Inventory '
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell 所有版本_

WMI 服务可以用来汇报许多关于计算机硬件的详细信息。通常，每种类型的硬件表现为一个对应的 WMI 类。不过，不太容易找出这些硬件的类。

由于所有硬件类都继承自相同的 WMI 根类（`CIM_LogicalDevice`），所以您可以使用这个根类来查找所有的硬件：

    Get-WmiObject -Class CIM_LogicalDevice | Out-GridView

这将返回一个基本的硬件清单。不过您还可以做更多的事情。通过一点额外的代码，您可以用 WMI 获取一个硬件的类名清单：

    Get-WmiObject -Class CIM_LogicalDevice |
      Select-Object -Property __Class, Description |
      Sort-Object -Property __Class -Unique |
      Out-GridView

您现在可以使用这些类名中的任意一个来查询某种特定的硬件，获取其详细信息：


    PS> Get-WmiObject -Class Win32_SoundDevice

    Manufacturer        Name                Status                       StatusInfo
    ------------        ----                ------                       ----------
    Cirrus Logic, Inc.  Cirrus Logic CS4... OK                                    3
    Intel(R) Corpora... Intel(R) Display... OK                                    3

<!--本文国际来源：[WMI Device Inventory ](http://community.idera.com/powershell/powertips/b/tips/posts/wmi-device-inventory)-->
