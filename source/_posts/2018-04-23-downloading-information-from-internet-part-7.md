---
layout: post
date: 2018-04-23 00:00:00
title: "PowerShell 技能连载 - 从 Internet 下载信息（第 7 部分）"
description: PowerTip of the Day - Downloading Information from Internet (Part 7)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在这个迷你系列中的该部分，我们将演示如何用 `Invoke-WebRequest` 从 internet 下载文件。只需要用 `-OutFile` 参数。这段代码下载 PNG 格式的 PowerShell 图标到桌面上：

```powershell
$url = "http://www.dotnet-lexikon.de/grafik/Lexikon/Windowspowershell.png"
$destination = "$home\powershell.png"

Invoke-WebRequest -Uri $url -OutFile $destination -UseBasicParsing
Invoke-Item -Path $destination
```

请注意 `Invoke-WebRequest` 只能从 HTTP 地址下载文件。如果从 HTTPS 地址下载将会报错。请查看我们的下一个技能如何解决它！

<!--本文国际来源：[Downloading Information from Internet (Part 7)](http://community.idera.com/powershell/powertips/b/tips/posts/downloading-information-from-internet-part-7)-->
