---
layout: post
date: 2020-04-30 00:00:00
title: "PowerShell 技能连载 - 读取机箱的 SKU"
description: PowerTip of the Day - Reading Chassis SKU
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 Windows 10 和 Server 2016中，WMI 添加了一个新属性，该属性简化了机箱或机壳 SKU 的收集。以下这行代码能够读取 SKU：

```powershell
PS> Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -Property Name, ChassisSKUNumber

Name            ChassisSKUNumber
----            ----------------
DESKTOP-8DVNI43 Convertible
```

SKU 编号仅仅是通用的“可替换编号”（对于笔记本电脑）还是一个独立的编号，取决于制造商和 BIOS 设置。

一个更有希望的类是 `Win32_SystemEnclosure`，它存在于所有 Windows 版本中：

```powershell
PS> Get-CimInstance -ClassName Win32_SystemEnclosure | Select-Object -Property Manufacturer, SerialNumber, LockPresent

Manufacturer SerialNumber LockPresent
------------ ------------ -----------
Dell Inc.    4ZKM0Z2            False
```

<!--本文国际来源：[Reading Chassis SKU](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/reading-chassis-sku)-->

