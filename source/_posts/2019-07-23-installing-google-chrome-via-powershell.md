---
layout: post
date: 2019-07-23 00:00:00
title: "PowerShell 技能连载 - 通过 PowerShell 安装 Google Chrome"
description: PowerTip of the Day - Installing Google Chrome via PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
要下载并安装谷歌Chrome浏览器，只需几个常见的 PowerShell 命令组合：

```powershell
$Installer = "$env:temp\chrome_installer.exe"
$url = 'http://dl.google.com/chrome/install/375.126/chrome_installer.exe'
Invoke-WebRequest -Uri $url -OutFile $Installer -UseBasicParsing
Start-Process -FilePath $Installer -Args '/silent /install' -Wait
Remove-Item -Path $Installer
```

<!--本文国际来源：[Installing Google Chrome via PowerShell](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/installing-google-chrome-via-powershell)-->

