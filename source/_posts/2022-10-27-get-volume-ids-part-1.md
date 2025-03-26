---
layout: post
date: 2022-10-27 00:00:00
title: "PowerShell 技能连载 - 获取卷 ID（第 1 部分）"
description: PowerTip of the Day - Get Volume IDs (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
您可以查询 WMI 以获取类似驱动器卷 ID 的列表：

```powershell
Get-CimInstance -ClassName Win32_Volume |
Select-Object -Property DriveLetter, DeviceID, SerialNumber, Capacity
```

<!--本文国际来源：[Get Volume IDs (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/get-volume-ids-part-1)-->

