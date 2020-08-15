---
layout: post
date: 2020-08-06 00:00:00
title: "PowerShell 技能连载 - 读取 4K 哈希"
description: PowerTip of the Day - Reading 4K-Hash
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Windows 操作系统可以通过所谓的 4K 哈希来唯一标识：这是一个特殊的哈希字符串，大小为 4000 字节。您可以将此哈希与 "Windows Autopilot" 一起使用，以添加物理机和虚拟机。

4K 哈希是注册 Windows 机器所需的一条信息，但是它本身也很有趣，它也可以唯一地标识 Windows 操作系统用于其他目的。下面的代码通过 WMI 读取唯一的 4K 哈希（需要管理员特权）：

```powershell
$info = Get-CimInstance -Namespace root/cimv2/mdm/dmmap -Class MDM_DevDetail_Ext01 -Filter "InstanceID='Ext' AND ParentID='./DevDetail'"
$4khh = $info.DeviceHardwareData

$4khh
```

由于 `Get-CimInstance` 支持远程处理，因此您也可以从远程系统（即虚拟机）读取此值。

<!--本文国际来源：[Reading 4K-Hash](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/reading-4k-hash)-->

