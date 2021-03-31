---
layout: post
date: 2021-03-26 00:00:00
title: "PowerShell 技能连载 - 使用 BITS 来下载文件（第 1 部分）"
description: PowerTip of the Day - Using BITS to Download Files (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
BITS（后台智能传输系统）是 Windows 用于下载大文件（例如操作系统更新）的技术。您也可以使用相同的系统下载大文件。另外一个好处是，在下载文件时，您会获得一个不错的进度条。本示例下载 NASA 火星报告并在下载后播放视频：

```powershell
$url = 'https://mars.nasa.gov/system/downloadable_items/41764_20180703_marsreport-1920.mp4'
$targetfolder = $env:temp
$filename = Split-Path -Path $url -Leaf
$targetFile = Join-Path -Path $targetfolder -ChildPath $filename

Start-BitsTransfer -Source $url -Destination $targetfolder -Description 'Downloading Video...' -Priority Low


Start-Process -FilePath $targetFile
```

请注意 `Start-BitsTransfer` 如何让您选择下载优先级，这样您就可以下载文件而不会占用更重要的事情所需的网络带宽。另请注意，BITS 不适用于所有下载内容。服务器需要支持该技术。

<!--本文国际来源：[Using BITS to Download Files (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-bits-to-download-files-part-1)-->
