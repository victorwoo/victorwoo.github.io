---
layout: post
date: 2018-04-24 00:00:00
title: "PowerShell 技能连载 - 从 Internet 下载信息（第 8 部分）"
description: PowerTip of the Day - Downloading Information from Internet (Part 8)
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
在之前的技能中我们演示如何用 `Invoke-WebRequest` 从 internet 下载文件。然而，它只适用于 HTTP 地址。如果您用的是 HTTPS 地址，将会失败：

```powershell
$url = "https://github.com/PowerShellConferenceEU/2018/raw/master/Agenda_psconfeu_2018.pdf"
$destination = "$home\agenda.pdf"

Invoke-WebRequest -Uri $url -OutFile $destination -UseBasicParsing
Invoke-Item -Path $destination
```

一个简单的解决方法是先运行这行代码：

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
```

执行完这行代码之后，之前的代码就运行正常了，可以下载 psconf.eu PDF 格式的议程表到您的桌面上，然后尝试打开该文件。

<!--more-->
本文国际来源：[Downloading Information from Internet (Part 8)](http://community.idera.com/powershell/powertips/b/tips/posts/downloading-information-from-internet-part-8)
