---
layout: post
date: 2020-06-29 00:00:00
title: "PowerShell 技能连载 - 改变操作系统描述"
description: PowerTip of the Day - Changing Operating System Description
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
每个 Windows 操作系统都有一个描述，您可以使用以下命令查看（和更改）该描述：

```powershell
PS> control sysdm.cpl
```

要通过 PowerShell 自动执行此操作，请使用以下命令：

```powershell
# change operating system description
# (requires admin privileges)
$values = @{
    Description = 'My Computer'
}
Set-CimInstance -Query 'Select * from Win32_OperatingSystem' -Property $values

# read description
# (no admin privileges required)
$description = Get-CimInstance -ClassName Win32_OperatingSystem |
    Select-Object -ExpandProperty Description

"OS Description: $description"
```

<!--本文国际来源：[Changing Operating System Description](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/changing-operating-system-description)-->

