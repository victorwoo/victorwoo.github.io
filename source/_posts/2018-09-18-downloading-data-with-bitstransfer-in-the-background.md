---
layout: post
date: 2018-09-18 00:00:00
title: "PowerShell 技能连载 - 用 BitsTransfer 在后台下载数据"
description: PowerTip of the Day - Downloading Data with BitsTransfer in the Background
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
下载大型的文件是一个挑战，因为下载的过程可能比机器的开机时间还长。通过 BitsTransfer，您可以在后台下载文件，甚至当机器关机或重启后，仍然能够续传直到完成。

以下代码可以下载一段 NASA 的视频。然而，下载过程是在后台，而且你可以继续做别的事。实际上。当您关闭 PowerShell 甚至电脑之后，下次启动时下载仍会继续。

```powershell
$url = 'https://mars.nasa.gov/system/downloadable_items/41764_20180703_marsreport-1920.mp4'
$targetfolder = "$Home\Desktop"

Start-BitsTransfer -Source $url -Destination $targetfolder -Asynchronous -Priority Low
```

您需要做的只是偶尔查看一下 BitsTransfer，检查下载任务是否完成。当一个下载过程完成后，需要您负责完成下载。只有这样，所有下载的文件才会从后台缓冲区中复制到最终的目的地：

```powershell
Get-BitsTransfer |
Where-Object Jobstate -eq Transferred |
Complete-BitsTransfer
```

完成。

要获取挂起的 BitsTransfer 任务的更多信息，请试试这段代码：

```powershell
PS> Get-BitsTransfer | Select-Object -Property *
```

And if you have Admin privileges, you can even dump the jobs from other users, including internal accounts. This way you’ll see updates and other things that are on their way to you:
如果您有管理员特权，您甚至可以从其它用户那儿转储所有任务，包括内部账号。通过这种方式您可以查看进度等其它信息：

```powershell
PS> Get-BitsTransfer -AllUsers
```

<!--本文国际来源：[Downloading Data with BitsTransfer in the Background](http://community.idera.com/powershell/powertips/b/tips/posts/downloading-data-with-bitstransfer-in-the-background)-->
