---
layout: post
date: 2019-05-03 00:00:00
title: "PowerShell 技能连载 - 查找最新的 PowerShell 6 下载地址"
description: PowerTip of the Day - Finding the Latest PowerShell 6 Download URL
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 6 是开源的，所以经常发布新的更新。以下是如何查找最新的 PowerShell 6 发布地址的方法：

```powershell
$AllProtocols = [Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
[Net.ServicePointManager]::SecurityProtocol = $AllProtocols


# get the URL for the latest PowerShell 6 release
$url = "https://github.com/PowerShell/PowerShell/releases/latest?dummy=$(Get-Random)"
$request = [System.Net.WebRequest]::Create($url)
$request.AllowAutoRedirect=$false
$response = $request.GetResponse()
$realURL = $response.GetResponseHeader("Location")
$response.Close()
$response.Dispose()

# get the current version from that URL
$v = ($realURL -split '/v')[-1]

# create the download URL for the release of choice
# (adjust the end part to target the desired platform, architecture, and package format)
$platform = "win-x64.zip"
$static = "https://github.com/PowerShell/PowerShell/releases/download"
$url = "$static/v$version/PowerShell-$version-$platform"
```

这段代码生成 ZIP 格式的 64 位 Windows 版下载链接。如果您需要不同的发行版，只需要调整 `$platform` 中定义的平台部分。

当获得了下载链接，您可以通过它自动完成剩下的步骤：下载 ZIP 文件，取消禁用并解压，然后执行 PowerShell 6:

```powershell
# define the place to download to
$destinationFile = "$env:temp\PS6\powershell6.zip"
$destinationFolder = Split-Path -Path $destinationFile

# create destination folder if it is not present
$existsDestination = Test-Path -Path $destinationFolder
if ($existsDestination -eq $false)
{
    $null = New-Item -Path $destinationFolder -Force -ItemType Directory
}

# download file
Invoke-WebRequest -Uri $url -OutFile $destinationFile
# unblock downloaded file
Unblock-File -Path $destinationFile
# extract file
Expand-Archive -Path $destinationFile -DestinationPath $destinationFolder -Force
```

最终，在桌面上创建一个快捷方式，指向 PowerShell 6 这样可以快捷地启动 shell：

```powershell
# place a shortcut on your desktop
$path = "$Home\Desktop\powershell6.lnk"
$obj = New-Object -ComObject WScript.Shell
$scut = $obj.CreateShortcut($path)
$scut.TargetPath = "$destinationFolder\pwsh.exe"
$scut.IconLocation = "$destinationFolder\pwsh.exe,0"
$scut.WorkingDirectory = "$home\Documents"
$scut.Save()

# run PowerShell 6
Invoke-Item -Path $path
```

<!--本文国际来源：[Finding the Latest PowerShell 6 Download URL](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/finding-the-latest-powershell-6-download-url)-->

