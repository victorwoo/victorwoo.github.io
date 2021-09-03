---
layout: post
date: 2021-08-27 00:00:00
title: "PowerShell 技能连载 - 使用 FTP：列出文件夹（第 1 部分）"
description: 'PowerTip of the Day - Using FTP: Listing Folders (Part 1)'
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

要显示 FTP 文件夹的内容，请尝试使用以下代码：

```powershell
$username='testuser'
$password='P@ssw0rd'
$ftp='ftp://192.168.1.123'
$subfolder='/'

[System.Uri]$uri = $ftp + $subfolder
$ftprequest=[System.Net.FtpWebRequest]::Create($uri)
$ftprequest.Credentials= [System.Net.NetworkCredential]::new($username,$password)
$ftprequest.Method=[System.Net.WebRequestMethods+Ftp]::ListDirectory
$response=$ftprequest.GetResponse()
$stream=$response.GetResponseStream()
$reader=[System.IO.StreamReader]::new($stream,[System.Text.Encoding]::UTF8)
$content=$reader.ReadToEnd()

$content
```

<!--本文国际来源：[Using FTP: Listing Folders (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-ftp-listing-folders-part-1)-->

