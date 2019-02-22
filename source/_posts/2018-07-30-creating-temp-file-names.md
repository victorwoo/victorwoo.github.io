---
layout: post
date: 2018-07-30 00:00:00
title: "PowerShell 技能连载 - 创建临时文件名"
description: PowerTip of the Day - Creating Temp File Names
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您需要写入信息到磁盘时，使用唯一的临时文件名是合理的。如果您使用静态的文件名并且多次运行您的代码，会一次又一次地覆盖写入同一个文件。如果某个人打开该文件并锁定它，将导致脚本执行失败。

以下是一些简单的生成唯一的临时文件名的方法：

```powershell
# use a random number (slight chance of duplicates)
$path = "$env:temp\liste$(Get-Random).csv"
"Path is: $path"

# use a GUID. Guaranteed to be unique but somewhat hard on the human eye
$path = "$env:temp\liste$([Guid]::NewGuid().toString()).csv"
"Path is: $path"

# use timestamp with milliseconds
$path = "$env:temp\liste$(Get-Date -format yyyy-MM-dd_HHmmss_ffff).csv"
"Path is: $path"
```

<!--本文国际来源：[Creating Temp File Names](http://community.idera.com/powershell/powertips/b/tips/posts/creating-temp-file-names)-->
