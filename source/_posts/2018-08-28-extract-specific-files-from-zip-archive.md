---
layout: post
date: 2018-08-28 00:00:00
title: "PowerShell 技能连载 - 从 ZIP 压缩包中解压指定的文件"
description: PowerTip of the Day - Extract Specific Files from ZIP Archive
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
PowerShell 提供了新的 cmdlet，例如 `Extract-Archive`，可以从一个 ZIP 文件中解压（所有的）文件。然而，只能解压整个压缩包。

如果您希望解压独立的文件，您可以使用 .NET 方法。以下是一个实现的示例：

* 它打开一个 ZIP 文件来读取内容
* 它查找该 ZIP 文件中所有符合指定文件扩展名的文件
* 它只解压这些文件到您指定的输出目录

代码中的注释解释了代码在做什么。只需要确保您调整了初始变量并且制定了一个存在的 ZIP 文件，以及一个在 ZIP 文件中存在的文件扩展名：

```powershell
#requires -Version 5.0

# change $Path to a ZIP file that exists on your system!
$Path = "$Home\Desktop\Test.zip"

# change extension filter to a file extension that exists
# inside your ZIP file
$Filter = '*.wav'

# change output path to a folder where you want the extracted
# files to appear
$OutPath = 'C:\ZIPFiles'

# ensure the output folder exists
$exists = Test-Path -Path $OutPath
if ($exists -eq $false)
{
  $null = New-Item -Path $OutPath -ItemType Directory -Force
}

# load ZIP methods
Add-Type -AssemblyName System.IO.Compression.FileSystem

# open ZIP archive for reading
$zip = [System.IO.Compression.ZipFile]::OpenRead($Path)

# find all files in ZIP that match the filter (i.e. file extension)
$zip.Entries | 
  Where-Object { $_.FullName -like $Filter } |
  ForEach-Object { 
    # extract the selected items from the ZIP archive
    # and copy them to the out folder
    $FileName = $_.Name
    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, "$OutPath\$FileName", $true)
    }

# close ZIP file
$zip.Dispose()

# open out folder
explorer $OutPath
```

<!--more-->
本文国际来源：[Extract Specific Files from ZIP Archive](http://community.idera.com/powershell/powertips/b/tips/posts/extract-specific-files-from-zip-archive)
