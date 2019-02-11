---
layout: post
date: 2019-01-24 00:00:00
title: "PowerShell 技能连载 - PowerShell 速查表汇编（第 2 部分）"
description: PowerTip of the Day - PowerShell Cheat Sheet Compilation (Part 2)
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
在前一个技能中我们提供了一个很棒的 PowerShell 速查表。让我们来看看 PowerShell 能够怎样下载这些速查表：

```powershell
# enable SSL download
$AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols

# download page
$url = "https://github.com/PrateekKumarSingh/CheatSheets/tree/master/Powershell"
$page = Invoke-WebRequest -UseBasicParsing -Uri $url
$links = $page.Links | 
    Where-Object { $_.href -like '*.pdf' } |
    Select-Object -Property title, href |
    # turn URLs into directly downloadable absolute URLs
    ForEach-Object {
        $_.href = 'https://github.com/PrateekKumarSingh/CheatSheets/raw/master/Powershell/' + $_.title
        $_
    }

# create folder on your desktop
$Path = "$home\Desktop\CheatSheets"
$exists = Test-Path -Path $Path
if (!$exists) { $null = New-Item -Path $path -ItemType Directory }

# download cheat sheets
$links | ForEach-Object {
    $docPath = Join-Path -Path $Path -ChildPath $_.Title
    Start-BitsTransfer -Source $_.href -Destination $docPath -Description $_.title
    # alternate way of downloading
    # Invoke-WebRequest -UseBasicParsing -Uri $_.href -OutFile $docPath
}

# open folder
explorer $Path
```

当您运行这段脚本时，PowerShell 将下载所有的速查表并且将它们存放在桌面上一个名为 "CheatSheets" 的新文件夹中。祝您读得愉快！

<!--more-->
本文国际来源：[PowerShell Cheat Sheet Compilation (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/powershell-cheat-sheet-compilation-part-2)
