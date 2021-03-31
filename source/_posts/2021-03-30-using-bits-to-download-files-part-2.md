---
layout: post
date: 2021-03-30 00:00:00
title: "PowerShell 技能连载 - 使用 BITS 来下载文件（第 2 部分）"
description: PowerTip of the Day - Using BITS to Download Files (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
BITS（背景智能传输系统）是Windows用于下载大文件（例如操作系统更新）的技术。您也可以使用该服务，例如异步下载文件。执行此操作时，您无需等待下载完成，甚至可以在几天内跨越多次重启下载超大文件。每当用户再次登录时，下载就会继续。

下面的示例代码以较低优先级的异步后台任务下载 NASA 火星报告：

```powershell
$url = 'https://mars.nasa.gov/system/downloadable_items/41764_20180703_marsreport-1920.mp4'
$targetfolder = $env:temp
Start-BitsTransfer -Source $url -Destination $targetfolder -Asynchronous -Priority Low
```

异步 BITS 传输的缺点是您需要手动完成文件传输，因为 BITS 会将数据下载到隐藏的缓存中。由您决定何时运行 `Get-BitsTransfer` 并确定已完成的作业，然后使用 `Complete-BitsTransfer` 完成文件传输。

本示例将检查是否已完成传输并完成下载：

```powershell
Get-BitsTransfer |
  ForEach-Object {
    Write-Warning $_.FileList.RemoteName
    $_
  } |
  Where-Object { $_.jobstate -eq 'Transferred'  } |
  ForEach-Object {
    #$_ | Select-Object -Property *
    $file = $_.FileList.LocalName
    Write-Warning "Copy file $file..."
    $_ | Complete-BitsTransfer
  }
```

Windows 正在使用相同的技术来下载大量的操作系统更新。如果您具有管理员特权，则可以检查由其他用户（包括操作系统）发起的 BITS 传输：

```powershell
PS> Get-BitsTransfer -AllUsers

JobId                                DisplayName                                          TransferType JobState
-----                                -----------                                          ------------ ------
18514439-0e92-4ca8-88b4-4b2aa0036114 MicrosoftMapsBingGeoStore                            Download     Sus...
9e76ff92-65e2-4b3c-bb01-263e485e986a Dell_Asimov.C18EE5B49BDB373421EFA627336E417FC7EBB5B3 Download     Sus...
7bd117fe-2326-4198-a2a6-884022acb3ad Dell_Asimov.F10AAAECCA3ED0E344B68351EB619B5356E6C3C5 Download     Sus...

PS> Get-BitsTransfer -AllUsers | Select-Object OwnerAccount, Priority, FileList

OwnerAccount                  Priority FileList
------------                  -------- --------
NT AUTHORITY\NETWORK SERVICE    Normal {}
NT AUTHORITY\SYSTEM         Foreground {https://downloads.dell.com/catalog/CatalogIndexPC.cab}
NT AUTHORITY\SYSTEM         Foreground {https://dellupdater.dell.com/non_du/ClientService/Catalog/CatalogI...
```

<!--本文国际来源：[Using BITS to Download Files (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-bits-to-download-files-part-2)-->

