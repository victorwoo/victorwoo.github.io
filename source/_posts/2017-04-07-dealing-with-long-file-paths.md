layout: post
date: 2017-04-07 00:00:00
title: "PowerShell 技能连载 - 处理长文件路径"
description: PowerTip of the Day - Dealing with Long File Paths
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
以前，当路径长于 256 字符时，Windows 文件系统有时会变得缓慢。在 PowerShell Gallery 有一个 module，增加了一系列 cmdlet，可以快速搜索文件系统，并且支持任意长度的路径。


如果您使用 PowerShell 5 或安装了 PowerShellGet([www.powershellgallery.com](http://www.powershellgallery.com))，那么您可以从 PowerShell Gallery 中下载和安装 "PSAlphaFS" module：

```powershell
Install-Module -Name PSAlphaFS -Scope CurrentUser
```

不幸的是，这些 cmdlet 似乎需要完整的管理员特权，而对普通用户会抛出异常。如果您是管理员，您可以以这种方式查找长路径的文件：

```powershell
Get-LongChildItem -Path c:\windows -Recurse -File |
    Where-Object { $_.FullName.Length -gt 250 }
```

<!--more-->
本文国际来源：[Dealing with Long File Paths](http://community.idera.com/powershell/powertips/b/tips/posts/dealing-with-long-file-paths)
