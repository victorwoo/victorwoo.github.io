---
layout: post
date: 2021-09-02 00:00:00
title: "PowerShell 技能连载 - 使用 FTP：下载二进制文件（第 3 部分）"
description: 'PowerTip of the Day - Using FTP: Downloading Binary File (Part 3)'
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

要以二进制模式从 FTP 服务器下载文件，请尝试以下代码，该代码还说明了如何使用显式凭据进行身份验证：

```powershell
$username='testuser'
$password='P@ssw0rd'
[System.Uri]$uri='ftp://192.168.1.123/test.txt'

$localFile = 'C:\test.txt'

$ftprequest=[System.Net.FtpWebRequest]::Create($uri)
$ftprequest.Credentials=[System.Net.NetworkCredential]::new($username,$password)
$ftprequest.Method=[System.Net.WebRequestMethods+Ftp]::DownloadFile
$ftprequest.UseBinary = $true
$ftprequest.KeepAlive = $false
$response=$ftprequest.GetResponse()
$stream=$response.GetResponseStream()

try
{
    $targetfile = [System.IO.FileStream]::($localFile,[IO.FileMode]::Create)
    [byte[]]$readbuffer = New-Object byte[] 1024

    do{
        $readlength = $stream.Read($readbuffer,0,1024)
        $targetfile.Write($readbuffer,0,$readlength)
    }
    while ($readlength -gt 0)

    $targetfile.Close()
}
catch
{
    Write-Warning "Error occurred: $_"
}
```

<!--本文国际来源：[Using FTP: Downloading Binary File (Part 3)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-ftp-downloading-binary-file-part-3)-->

