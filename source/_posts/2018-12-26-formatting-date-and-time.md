---
layout: post
date: 2018-12-26 00:00:00
title: "PowerShell 技能连载 - 格式化日期和时间"
description: PowerTip of the Day - Formatting Date and Time
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
通过 `Get-Date` 的 `-Format` 参数可以方便地将日期和时间格式化为您所需的格式。您可以对当前时间使用它，也可以对外部的 `DateTime` 变量使用它。只需要使用日期和时间的格式化字符串就可以转换为您所需的输出格式。

以下是一些例子。例如要将当前日期暗 ISO 格式输出，请运行以下代码：

```powershell
PS> Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
2018-12-02 11:36:37
```

使用现有的或从别处读取的 datetime 对象的方法是 将它传给 `Get-Date` 的 `-Date` 属性：

```powershell
# find out last boot time
$os = Get-CimInstance -ClassName Win32_OperatingSystem
$lastBoot = $os.LastBootUpTime

# raw datetime output
$lastBoot

# formatted string output
Get-Date -Date $lastBoot -Format '"Last reboot at" MMM dd, yyyy "at" HH:mm:ss "and" fffff "Milliseconds.
```

格式化字符串既可以包括日期时间的通配符，也可以包括静态文本。只需要确保用双引号将静态文本包括起来。以下是执行结果（在德语系统上）：

    Donnerstag, 22. November 2018 01:13:44
    
    Last reboot at Nov 22, 2018 at 01:13:44 and 50000 Milliseconds.


<!--more-->
本文国际来源：[Formatting Date and Time](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/formatting-date-and-time)
