---
layout: post
date: 2021-08-31 00:00:00
title: "PowerShell 技能连载 - 使用 FTP：下载文件（第 2 部分）"
description: 'PowerTip of the Day - Using FTP: Downloading File (Part 2)'
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 不附带用于通过 FTP 下载和上传数据的 cmdlet。但是，您可以为此使用 .NET。

要从 FTP 服务器下载文件，请尝试使用以下代码：

```powershell
$localFile = "C:\test.txt"

$username='testuser'
$password='P@ssw0rd'

[System.Uri]$uri = "ftp://${username}:$password@192.168.1.123/test.txt"
$webclient = [System.Net.WebClient]::new()
$webclient.DownloadFile($uri, $localFile)
$webclient.Dispose()
```

<!--本文国际来源：[Using FTP: Downloading File (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-ftp-downloading-file-part-2)-->

