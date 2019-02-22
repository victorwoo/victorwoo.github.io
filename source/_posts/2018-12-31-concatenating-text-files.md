---
layout: post
date: 2018-12-31 00:00:00
title: "PowerShell 技能连载 - 连接文本文件"
description: PowerTip of the Day - Concatenating Text Files
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
假设一个脚本已经向某个文件夹写入了多个日志文件，所有文件名都为 *.log。您可能希望将它们合并为一个大文件。以下是一个简单的实践：

```powershell
$OutPath = "$env:temp\summary.log"

Get-Content -Path "C:\Users\tobwe\Documents\ScriptOutput\*.log" |
  Set-Content $OutPath

Invoke-Item -Path $OutPath
```

然而，这个方法并不能提供充分的控制权：所有文件需要放置在同一个文件夹中，并且必须有相同的文件扩展名，而且您无法控制它们合并的顺序。

一个更多功能的方法类似这样：

```powershell
$OutPath = "$env:temp\summary.log"

Get-ChildItem -Path "C:\Users\demouser\Documents\Scripts\*.log" -Recurse -File |
    Sort-Object -Property LastWriteTime -Descending |
    Get-Content |
    Set-Content $OutPath

Invoke-Item -Path $OutPath
```

它利用了 `Get-ChildItem` 的灵活性，而且可以在读取内容之前对文件排序。通过这种方法，日志保持了顺序，并且最终的日志信息总是在日志文件的最上部。

<!--本文国际来源：[Concatenating Text Files](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/concatenating-text-files)-->
