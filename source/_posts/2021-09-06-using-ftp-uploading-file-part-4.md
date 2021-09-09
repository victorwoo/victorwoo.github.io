---
layout: post
date: 2021-09-06 00:00:00
title: "PowerShell 技能连载 - 使用 FTP：上传文件（第 4 部分）"
description: 'PowerTip of the Day - Using FTP: Uploading File (Part 4)'
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 不附带用于通过 FTP 下载和上传数据的 cmdlet。但是，您可以使用 .NET 来实现。

要将文件从本地驱动器上传到 FTP 服务器，请尝试以下代码：

```powershell
$localFile = "C:\test.txt"

$username='testuser'
$password='P@ssw0rd'

[System.Uri]$uri = "ftp://${username}:$password@192.168.1.123/test.txt"
$webclient = [System.Net.WebClient]::new()
$webclient.UploadFile($uri, $localFile)
$webclient.Dispose()
```

<!--本文国际来源：[Using FTP: Uploading File (Part 4)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-ftp-uploading-file-part-4)-->

