---
layout: post
date: 2017-06-22 00:00:00
title: "PowerShell 技能连载 - 使用缓存的端口文件"
description: PowerTip of the Day - Using Cached Port File
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们介绍了如何用 PowerShell 通过 IANA 下载端口分配信息。这个过程需要 Internet 连接并且需要一段时间。所以以下代码会查找缓存的 CSV 文件。如果缓存文件存在，端口信息会从离线文件中加载，否则将在线加载数据，并写入缓存文件。请特别注意如何使用 `Tee-Object` 命令创建缓存文件：

```powershell
$url = 'https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.csv'
$CSVFile = "$env:temp\ports.csv"
$exists = Test-Path -Path $CSVFile

if (!$exists)
{
  Write-Warning "Retrieving data online..."

  $portinfo = Invoke-WebRequest -Uri $Url -UseBasicParsing | `
    Select-Object -ExpandProperty Content | `
    Tee-Object -FilePath $CSVFile | ConvertFrom-Csv
}
else
{
  Write-Warning "Loading cached file..."
  $portinfo = Import-Csv -Path $CSVFile
}

$portinfo | Out-GridView
```

<!--本文国际来源：[Using Cached Port File](http://community.idera.com/powershell/powertips/b/tips/posts/using-cached-port-file)-->
