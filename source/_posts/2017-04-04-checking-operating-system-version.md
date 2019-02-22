---
layout: post
date: 2017-04-04 00:00:00
title: "PowerShell 技能连载 - 检查操作系统版本"
description: PowerTip of the Day - Checking Operating System Version
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
以下是一个简单快速的检查操作系统版本的方法：

```powershell
PS C:\> [Environment]::OSVersion


Platform ServicePack Version      VersionString                    
-------- ----------- -------      -------------                    
    Win32NT             10.0.14393.0 Microsoft Windows NT 10.0.14393.0
```

所以要检查一个脚本是否运行在一个预定的操作系统上变得十分简单。例如要检查是否运行在 Windows 10 上，请试试这行代码：

```powershell
PS C:\> [Environment]::OSVersion.Version.Major -eq 10

True
```

<!--本文国际来源：[Checking Operating System Version](http://community.idera.com/powershell/powertips/b/tips/posts/checking-operating-system-version)-->
