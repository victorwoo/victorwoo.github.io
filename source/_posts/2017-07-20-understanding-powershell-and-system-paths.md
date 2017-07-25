---
layout: post
date: 2017-07-20 00:00:00
title: "PowerShell 技能连载 - 理解 PowerShell 和文件系统"
description: PowerTip of the Day - Understanding PowerShell and System Paths
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
PowerShell 维护着它自己的位置：

```powershell
    PS> Get-Location

    Path
    ----
    C:\Users\tobwe
```

当前路径指向所有 cmdlet 使用的相对路径。

```powershell
    PS> Get-Location

    Path
    ----
    C:\Users\tobwe



    PS> Resolve-Path -Path .

    Path
    ----
    C:\Users\tobwe
```

还有另一个当前路径，是由 Windows 维护的，影响所有 .NET 方法。它可能 PowerShell 的当前路径不同：

```powershell
    PS> [Environment]::CurrentDirectory
    C:\test

    PS> [System.IO.Path]::GetFullPath('.')
    C:\test

    PS>
```

所以如果在脚本中使用跟文件系统有关的 .NET 方法，可能需要先同步两个路径。这行代码确保 .NET 使用和 PowerShell 相同的文件系统路径：

```powershell
PS> [Environment]::CurrentDirectory = $ExecutionContext.SessionState.Path.CurrentFileSystemLocation
```

同步之后，cmdlet 和 .NET 方法在同一个路径上工作：

```powershell
    PS> [Environment]::CurrentDirectory = $ExecutionContext.SessionState.Path.CurrentFileSystemLocation

    PS> [System.IO.Path]::GetFullPath('.')
    C:\Users\tobwe

    PS> Resolve-Path '.'

    Path
    ----
    C:\Users\tobwe
```

<!--more-->
本文国际来源：[Understanding PowerShell and System Paths](http://community.idera.com/powershell/powertips/b/tips/posts/understanding-powershell-and-system-paths)
