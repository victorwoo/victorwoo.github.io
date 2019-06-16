---
layout: post
date: 2019-06-07 00:00:00
title: "PowerShell 技能连载 - 查看下载文件的大小"
description: PowerTip of the Day - Finding Size of Download
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您用 PowerShell 从 internet 下载文件，您可能会想知道下载需要多少时间。您可以检查已下载的数据大小，而且在知道总下载尺寸的情况下可以计算进度百分比。

以下是得到文件尺寸的快速方法：

```powershell
function Get-DownloadSize
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory,ValueFromPipeline)]
    [String]
    $Url
  )

  process
  {
    $webRequest = [System.Net.WebRequest]::Create($Url)
    $response = $webRequest.GetResponse()
    $response.ContentLength
    $response.Dispose()
  }
}
```

以下是一个示例：

```powershell
PS> "https://github.com/PowerShell/PowerShell/releases/download/v6.2.1/PowerShell-6.2.1-win-x64.zip" | Get-DownloadSize

58716786
```

<!--本文国际来源：[Finding Size of Download](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/finding-size-of-download)-->

