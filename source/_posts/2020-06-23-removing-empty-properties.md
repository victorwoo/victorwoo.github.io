---
layout: post
date: 2020-06-23 00:00:00
title: "PowerShell 技能连载 - 移除空白的属性"
description: PowerTip of the Day - Removing Empty Properties
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
WMI 和 `Get-CimInstance` 可以为您提供许多有用的信息，但是返回的对象通常包含许多空属性：

```powershell
PS> Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -Property *
```

另外，属性不一定要排序。您可以通过识别和排序不为空的属性来进行修复：

```powershell
# get all WMI information
$os = Get-CimInstance -ClassName Win32_OperatingSystem
# find names of non-empty properties
$filledProperties = $os.PSObject.Properties.Name.Where{![string]::IsNullOrWhiteSpace($os.$_)} | Sort-Object
# show non-empty properties only
$os | Select-Object -Property $filledProperties
```

<!--本文国际来源：[Removing Empty Properties](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/removing-empty-properties)-->

