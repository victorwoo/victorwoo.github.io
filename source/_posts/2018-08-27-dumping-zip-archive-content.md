---
layout: post
date: 2018-08-27 00:00:00
title: "PowerShell 技能连载 - 提取 ZIP 压缩包信息"
description: PowerTip of the Day - Dumping ZIP Archive Content
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
PowerShell 提供了新的 cmdlet，例如 `Extract-Archive`，可以从一个 ZIP 文件中解压（所有的）文件。然而，并没有方法列出一个 ZIP 文件中的内容。

要实现这个目的，您可以使用 `Extract-Archive` 中使用的 .NET 库。这段代码将输入一个 ZIP 文件并提取它的内容（请确保您将 ZIP 的路径改为一个实际存在的路径）：

```powershell
# adjust this to a valid path to a ZIP file
$Path = "$Home\Desktop\Test.zip"

# load the ZIP types
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($Path)
$zip.Entries

$zip.Dispose()
```

<!--more-->
本文国际来源：[Dumping ZIP Archive Content](http://community.idera.com/powershell/powertips/b/tips/posts/dumping-zip-archive-content)
