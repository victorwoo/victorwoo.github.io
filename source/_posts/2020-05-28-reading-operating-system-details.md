---
layout: post
date: 2020-05-28 00:00:00
title: "PowerShell 技能连载 - 读取操作系统详情"
description: PowerTip of the Day - Reading Operating System Details
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
通过读取适当的注册表值，PowerShell 可以轻松检索重要的操作系统详细信息，例如内部版本号和版本：

```powershell
# read operating system info
Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion' |
# pick selected properties
Select-Object -Property CurrentBuild,CurrentVersion,ProductId, ReleaseID, UBR
```

不过，其中一些值使用加密格式。例如，`InstallTime` 注册表项只是一个非常大的整数。

```powershell
PS> $key = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
PS> (Get-ItemProperty -Path $key).InstallTime

132119809618946052
```

事实证明，这些是时间 tick 值，通过使用 `[DateTime]`类型及其 `FromFileTime()` 静态方法，您可以轻松地将时间 tick 值转换为有意义的安装日期：

```powershell
PS> $key = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
PS> $ticks = (Get-ItemProperty -Path $key).InstallTime
PS> $date = [DateTime]::FromFileTime($ticks)
PS> "Your OS Install Date: $date"

Your OS Install Date: 09/03/2019 12:42:41
```

您可以在遇到时间 tick 值时使用 `FromFileTime()`。例如，Active Directory 也以这种格式存储日期。

<!--本文国际来源：[Reading Operating System Details](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/reading-operating-system-details)-->

