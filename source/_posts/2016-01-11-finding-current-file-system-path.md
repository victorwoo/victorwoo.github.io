layout: post
date: 2016-01-11 12:00:00
title: "PowerShell 技能连载 - 查找当前文件系统路径"
description: PowerTip of the Day - Finding Current File System Path
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
PowerShell 不仅支持文件系统，您可以将当前路径设置为别的 provider（用 `Set-Location` 命令）。以下是一个始终返回当前文件系统，无论当前激活的是那个 provider 的技巧：

```shell
PS C:\> cd hkcu:\

PS HKCU:\> $ExecutionContext.SessionState.Path

CurrentLocation CurrentFileSystemLocation
--------------- -------------------------
HKCU:\          C:\                      


​    
PS HKCU:\> $ExecutionContext.SessionState.Path.CurrentFileSystemLocation

Path
----
C:\ 


​    
PS HKCU:\> $ExecutionContext.SessionState.Path.CurrentFileSystemLocation.Path
C:\ 
```

<!--more-->
本文国际来源：[Finding Current File System Path](http://community.idera.com/powershell/powertips/b/tips/posts/finding-current-file-system-path)
