---
layout: post
date: 2021-10-18 00:00:00
title: "PowerShell 技能连载 - 将 Ticks 转换为 DateTime"
description: PowerTip of the Day - Converting Ticks to DateTime
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
偶尔，日期和时间信息以所谓的“缺陷”的格式存储为 "Ticks"。 Ticks 是自 01/01/1601 以来，100 纳秒的单位数。Active Directory 在内部使用此格式，但您也可以在其他地方找到它。 以下是以 "Ticks" 为单位的 Windows 安装时间的示例：

```powershell
$values = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
$installDateTicks = $values.InstallTime

$installDateTicks
```

结果是（非常）大的 64 比特数字：

    132457820129777032


要将 Ticks 转换为 `DateTime`，请使用 `[DateTimeOffset]`：

```powershell
$values = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
$installDateTicks = $values.InstallTime

$installDate = [DateTimeOffset]::FromFileTime($installDateTicks)
$installDate.DateTime
```

<!--本文国际来源：[Converting Ticks to DateTime](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/converting-ticks-to-datetime)-->

