---
layout: post
date: 2022-04-14 00:00:00
title: "PowerShell 技能连载 - 利用 WMI（第 1 部分）"
description: PowerTip of the Day - Leveraging WMI (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
WMI 是一种用于查询计算机详细信息的 Windows 技术。如果您仍在使用已弃用的 `Get-WmiObject` cmdlet，则应重新考虑：

```powershell
PS> Get-WmiObject -Class Win32_BIOS

SMBIOSBIOSVersion : 1.9.1
Manufacturer      : Dell Inc.
Name              : 1.9.1
SerialNumber      : 4ZKM0Z2
Version           : DELL   - 20170001
```

切换到新的 `Get-CimInstance` cmdlet，它的工作原理非常相似：

```powershell
PS> Get-CimInstance -ClassName Win32_BIOS

SMBIOSBIOSVersion : 1.9.1
Manufacturer      : Dell Inc.
Name              : 1.9.1
SerialNumber      : 4ZKM0Z2
Version           : DELL   - 20170001
```

`Get-CimInstance` 的众多优点之一是它的 IntelliSense 支持：要找出可用的类名，只需按 TAB 或（在 ISE 或 VSCode 等图形编辑器中）按 CTRL+空格：

```powershell
PS> Get-CimInstance -ClassName Win32_\# <-press CTRL+SPACE with the cursor after "_"
```

最开始可能需要重复按几次按键，因为生成 IntelliSense 列表可能需要几秒钟，因此在您第一次按键时，IntelliSense 可能会超时。

`Get-CimInstance` 相对于 `Get-WmiObject` 的另一个优势是 `Get-CimInstance` 在 PowerShell 7 中也可用。 WMI 是一种基于 Windows 的技术。不要期望在 Linux 机器上找到 WMI 类。

<!--本文国际来源：[Leveraging WMI (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/leveraging-wmi-part-1)-->

