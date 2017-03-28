layout: post
date: 2016-10-31 00:00:00
title: "PowerShell 技能连载 - 从网站上下载图片"
description: PowerTip of the Day - Downloading Pictures from Website
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
有许多有趣的网站，其中一个是 [www.metabene.de](http://www.metabene.de) （至少面向德国访访客），有 33 页内容，艺术家展示了他的绘画，并提供免费下载（只允许私人使用·私人使用）。

在类似这种情况中，PowerShell 可以帮助您将手动从网站下载图片的操作自动化。在 PowerShell 3.0 中，引入了一个称为 `Invoke-WebRequest` 的“PowerShell 浏览器”，它能够将人类在一个真实浏览器中操作的大多数事情自动化。

当您运行这段脚本时，它访问所有的 33 个网页，检查所有的图片链接，并将它们保存到硬盘上：

```powershell
# open destination folder (and create it if needed)
$folder = 'c:\drawings'
$exists = Test-Path -Path $folder
if (!$exists) { $null = New-Item -Path $folder -ItemType Directory }
explorer $folder

# walk all 33 web pages that www.metabene.de offers
1..33 | ForEach-Object {
  $url = "http://www.metabene.de/galerie/page/$_"

  # navigate to website...
  $webpage = Invoke-WebRequest -Uri $url -UseBasicParsing

  # take sources of all images on this website...
  $webpage.Images.src |
  Where-Object {
    # take only images that were uploaded to this blog
    $_ -like '*/uploads/*'
  }
} |
ForEach-Object {
  # get filename of URL
  $filename = $_.Split('/')[-1]
  # create local file name
  $destination= Join-Path -Path $Folder -ChildPath $filename
  # download pictures
  Invoke-WebRequest -Uri $url -OutFile $destination
}
```

<!--more-->
本文国际来源：[Downloading Pictures from Website](http://community.idera.com/powershell/powertips/b/tips/posts/downloading-pictures-from-website)
